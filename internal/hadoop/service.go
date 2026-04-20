package hadoop

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
)

var tokenReplacer = strings.NewReplacer(
	".", " ",
	",", " ",
	";", " ",
	":", " ",
	"!", " ",
	"?", " ",
	"(", " ",
	")", " ",
	"[", " ",
	"]", " ",
	"{", " ",
	"}", " ",
	"\n", " ",
	"\t", " ",
)

type NameNode struct {
	Host           string    `json:"host"`
	Namespace      string    `json:"namespace"`
	ClusterID      string    `json:"cluster_id"`
	SafeMode       bool      `json:"safe_mode"`
	LastCheckpoint time.Time `json:"last_checkpoint"`
}

type DataNode struct {
	ID            string    `json:"id"`
	Host          string    `json:"host"`
	CapacityGB    int       `json:"capacity_gb"`
	UsedGB        int       `json:"used_gb"`
	Healthy       bool      `json:"healthy"`
	LastHeartbeat time.Time `json:"last_heartbeat"`
}

type SecondaryNameNode struct {
	Host                     string    `json:"host"`
	CheckpointEveryMinutes   int       `json:"checkpoint_every_minutes"`
	LastSuccessfulCheckpoint time.Time `json:"last_successful_checkpoint"`
}

type ClusterSnapshot struct {
	NameNode          NameNode          `json:"name_node"`
	SecondaryNameNode SecondaryNameNode `json:"secondary_name_node"`
	DataNodes         []DataNode        `json:"data_nodes"`
	ReplicationFactor int               `json:"replication_factor"`
}

type WordCountResult struct {
	Workers     int               `json:"workers"`
	TotalWords  int               `json:"total_words"`
	UniqueWords int               `json:"unique_words"`
	WordCounts  map[string]int    `json:"word_counts"`
	TopWords    []WordCountMetric `json:"top_words"`
	CompletedAt time.Time         `json:"completed_at"`
}

type WordCountMetric struct {
	Word  string `json:"word"`
	Count int    `json:"count"`
}

type SqoopPlanRequest struct {
	Direction string `json:"direction"`
	Source    string `json:"source"`
	Target    string `json:"target"`
	Table     string `json:"table"`
	SplitBy   string `json:"split_by"`
	Mappers   int    `json:"mappers"`
}

type SqoopPlan struct {
	Direction string   `json:"direction"`
	Command   string   `json:"command"`
	Checks    []string `json:"checks"`
}

type Service struct {
	mu      sync.RWMutex
	cluster ClusterSnapshot
}

const maxMapReduceWorkers = 32

func NewService() *Service {
	now := time.Now().UTC()
	return &Service{
		cluster: ClusterSnapshot{
			NameNode: NameNode{
				Host:           "namenode.acid.local",
				Namespace:      "acid-hdfs",
				ClusterID:      "acid-hdfs-cluster",
				SafeMode:       false,
				LastCheckpoint: now.Add(-10 * time.Minute),
			},
			SecondaryNameNode: SecondaryNameNode{
				Host:                     "secondary-namenode.acid.local",
				CheckpointEveryMinutes:   60,
				LastSuccessfulCheckpoint: now.Add(-9 * time.Minute),
			},
			DataNodes: []DataNode{
				{ID: "dn-1", Host: "datanode-1.acid.local", CapacityGB: 1024, UsedGB: 410, Healthy: true, LastHeartbeat: now.Add(-3 * time.Second)},
				{ID: "dn-2", Host: "datanode-2.acid.local", CapacityGB: 1024, UsedGB: 388, Healthy: true, LastHeartbeat: now.Add(-4 * time.Second)},
				{ID: "dn-3", Host: "datanode-3.acid.local", CapacityGB: 1024, UsedGB: 399, Healthy: true, LastHeartbeat: now.Add(-5 * time.Second)},
			},
			ReplicationFactor: 3,
		},
	}
}

func (s *Service) GetClusterSnapshot() ClusterSnapshot {
	s.mu.RLock()
	defer s.mu.RUnlock()

	dataNodes := make([]DataNode, len(s.cluster.DataNodes))
	copy(dataNodes, s.cluster.DataNodes)

	return ClusterSnapshot{
		NameNode:          s.cluster.NameNode,
		SecondaryNameNode: s.cluster.SecondaryNameNode,
		DataNodes:         dataNodes,
		ReplicationFactor: s.cluster.ReplicationFactor,
	}
}

func (s *Service) RunWordCount(text string, workers int) WordCountResult {
	if workers <= 0 {
		workers = 2
	}
	if workers > maxMapReduceWorkers {
		workers = maxMapReduceWorkers
	}

	tokens := tokenize(text)
	if len(tokens) == 0 {
		return WordCountResult{
			Workers:     workers,
			WordCounts:  map[string]int{},
			TopWords:    []WordCountMetric{},
			CompletedAt: time.Now().UTC(),
		}
	}

	workers = min(workers, len(tokens))
	chunkSize := (len(tokens) + workers - 1) / workers
	out := make(chan map[string]int, workers)
	var wg sync.WaitGroup

	for i := 0; i < workers; i++ {
		start := i * chunkSize
		if start >= len(tokens) {
			break
		}
		end := min(start+chunkSize, len(tokens))
		wg.Add(1)
		go func(slice []string) {
			defer wg.Done()
			m := make(map[string]int)
			for _, token := range slice {
				m[token]++
			}
			out <- m
		}(tokens[start:end])
	}

	go func() {
		wg.Wait()
		close(out)
	}()

	counts := make(map[string]int)
	for part := range out {
		for k, v := range part {
			counts[k] += v
		}
	}

	top := make([]WordCountMetric, 0, len(counts))
	for word, count := range counts {
		top = append(top, WordCountMetric{Word: word, Count: count})
	}
	sort.Slice(top, func(i, j int) bool {
		if top[i].Count == top[j].Count {
			return top[i].Word < top[j].Word
		}
		return top[i].Count > top[j].Count
	})
	if len(top) > 10 {
		top = top[:10]
	}

	return WordCountResult{
		Workers:     workers,
		TotalWords:  len(tokens),
		UniqueWords: len(counts),
		WordCounts:  counts,
		TopWords:    top,
		CompletedAt: time.Now().UTC(),
	}
}

func (s *Service) BuildSqoopPlan(req SqoopPlanRequest) (SqoopPlan, error) {
	direction := strings.ToLower(strings.TrimSpace(req.Direction))
	if direction != "import" && direction != "export" {
		return SqoopPlan{}, errors.New("direction must be import or export")
	}
	if strings.TrimSpace(req.Source) == "" || strings.TrimSpace(req.Target) == "" || strings.TrimSpace(req.Table) == "" {
		return SqoopPlan{}, errors.New("source, target and table are required")
	}
	if req.Mappers <= 0 {
		req.Mappers = 4
	}
	if strings.TrimSpace(req.SplitBy) == "" {
		req.SplitBy = "id"
	}

	base := "sqoop"
	var cmd string
	if direction == "import" {
		cmd = fmt.Sprintf(
			`%s import --connect "%s" --table "%s" --target-dir "%s" --split-by "%s" --num-mappers %d`,
			base,
			req.Source,
			req.Table,
			req.Target,
			req.SplitBy,
			req.Mappers,
		)
	} else {
		cmd = fmt.Sprintf(
			`%s export --connect "%s" --table "%s" --export-dir "%s" --num-mappers %d`,
			base,
			req.Target,
			req.Table,
			req.Source,
			req.Mappers,
		)
	}

	return SqoopPlan{
		Direction: direction,
		Command:   cmd,
		Checks: []string{
			"Ensure NameNode and DataNodes are healthy before transfer.",
			"Verify the table exists and split-by column has balanced cardinality.",
			"Run with test mode on a sample partition before full transfer.",
		},
	}, nil
}

func tokenize(text string) []string {
	cleaned := strings.ToLower(tokenReplacer.Replace(text))
	fields := strings.Fields(cleaned)
	if len(fields) == 0 {
		return nil
	}
	return fields
}
