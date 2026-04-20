package hadoop

import "testing"

func TestRunWordCount(t *testing.T) {
	svc := NewService()
	result := svc.RunWordCount("Map reduce map MAP reduce hadoop", 3)

	if result.TotalWords != 6 {
		t.Fatalf("expected 6 words, got %d", result.TotalWords)
	}
	if result.WordCounts["map"] != 3 {
		t.Fatalf("expected map count 3, got %d", result.WordCounts["map"])
	}
	if result.WordCounts["reduce"] != 2 {
		t.Fatalf("expected reduce count 2, got %d", result.WordCounts["reduce"])
	}
	if len(result.TopWords) == 0 || result.TopWords[0].Word != "map" {
		t.Fatalf("expected top word to be map, got %+v", result.TopWords)
	}
}

func TestBuildSqoopPlanValidation(t *testing.T) {
	svc := NewService()
	if _, err := svc.BuildSqoopPlan(SqoopPlanRequest{Direction: "invalid"}); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestBuildSqoopPlanImport(t *testing.T) {
	svc := NewService()
	plan, err := svc.BuildSqoopPlan(SqoopPlanRequest{
		Direction: "import",
		Source:    "jdbc:postgresql://localhost:5432/acid",
		Target:    "/acid/raw/customers",
		Table:     "customers",
		SplitBy:   "id",
		Mappers:   8,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if plan.Direction != "import" {
		t.Fatalf("expected import direction, got %q", plan.Direction)
	}
	if plan.Command == "" {
		t.Fatal("expected command to be generated")
	}
}
