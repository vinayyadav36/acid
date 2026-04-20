package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"acid/internal/hadoop"
)

func TestGetCluster(t *testing.T) {
	handler := NewHadoopHandler(hadoop.NewService())
	req := httptest.NewRequest(http.MethodGet, "/api/hadoop/cluster", nil)
	rec := httptest.NewRecorder()

	handler.GetCluster(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "name_node") {
		t.Fatalf("expected cluster payload, got %s", rec.Body.String())
	}
}

func TestBuildSqoopPlanRejectsBadPayload(t *testing.T) {
	handler := NewHadoopHandler(hadoop.NewService())
	req := httptest.NewRequest(http.MethodPost, "/api/hadoop/sqoop/plan", strings.NewReader(`{`))
	rec := httptest.NewRecorder()

	handler.BuildSqoopPlan(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", rec.Code)
	}
}

func TestBuildSqoopPlanSuccess(t *testing.T) {
	handler := NewHadoopHandler(hadoop.NewService())
	reqBody := `{"direction":"import","source":"jdbc:postgresql://localhost:5432/acid","target":"/acid/raw/customers","table":"customers","split_by":"id","mappers":4}`
	req := httptest.NewRequest(http.MethodPost, "/api/hadoop/sqoop/plan", strings.NewReader(reqBody))
	rec := httptest.NewRecorder()

	handler.BuildSqoopPlan(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	body := rec.Body.String()
	if !strings.Contains(body, `"direction":"import"`) || !strings.Contains(body, `"command":"sqoop import`) {
		t.Fatalf("unexpected response body: %s", body)
	}
}
