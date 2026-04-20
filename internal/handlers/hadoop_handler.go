package handlers

import (
	"encoding/json"
	"net/http"

	"acid/internal/hadoop"
)

type HadoopHandler struct {
	service *hadoop.Service
}

type wordCountRequest struct {
	Text    string `json:"text"`
	Workers int    `json:"workers"`
}

func NewHadoopHandler(service *hadoop.Service) *HadoopHandler {
	return &HadoopHandler{service: service}
}

func (h *HadoopHandler) GetCluster(w http.ResponseWriter, _ *http.Request) {
	writeJSONResponse(w, http.StatusOK, h.service.GetClusterSnapshot())
}

func (h *HadoopHandler) RunWordCount(w http.ResponseWriter, r *http.Request) {
	var req wordCountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONResponse(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

	result := h.service.RunWordCount(req.Text, req.Workers)
	writeJSONResponse(w, http.StatusOK, result)
}

func (h *HadoopHandler) BuildSqoopPlan(w http.ResponseWriter, r *http.Request) {
	var req hadoop.SqoopPlanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONResponse(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

	plan, err := h.service.BuildSqoopPlan(req)
	if err != nil {
		writeJSONResponse(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}

	writeJSONResponse(w, http.StatusOK, plan)
}

func writeJSONResponse(w http.ResponseWriter, status int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
