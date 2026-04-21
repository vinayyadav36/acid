package handlers

import (
	"encoding/json"
	"net/http"
)

type APIHandler struct {
	searchBackend string
	analyticsLake string
}

func NewAPIHandler(searchBackend, analyticsLake string) *APIHandler {
	return &APIHandler{
		searchBackend: searchBackend,
		analyticsLake: analyticsLake,
	}
}

func (h *APIHandler) GetAPIInfo(w http.ResponseWriter, r *http.Request) {
	info := map[string]interface{}{
		"name":    "Dynamic Database API",
		"version": "2.0",
		"capabilities": map[string]interface{}{
			"search_backend": h.searchBackend,
			"analytics_lake": h.analyticsLake,
		},
		"endpoints": []string{
			"GET /health",
			"GET /api/health",
			"GET /api/info",
			"POST /api/auth/register",
			"POST /api/auth/login",
			"POST /api/auth/logout",
			"GET /api/auth/me",
			"GET /api/auth/api-keys",
			"POST /api/auth/api-keys",
			"DELETE /api/auth/api-keys/{id}",
			"GET /api/tables",
			"GET /api/tables/{table}/schema",
			"GET /api/tables/{table}/records",
			"GET /api/tables/{table}/records/{pk}",
			"GET /api/tables/{table}/search",
			"GET /api/tables/{table}/stats",
			"GET /api/search",
			"GET /api/search/",
			"GET /api/cdc/status",
			"GET /api/hadoop/cluster",
			"POST /api/hadoop/mapreduce/wordcount",
			"POST /api/hadoop/sqoop/plan",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(info)
}
