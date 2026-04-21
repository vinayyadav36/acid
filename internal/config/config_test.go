package config

import "testing"

func TestLoadConfigUsesEnvironmentValues(t *testing.T) {
	t.Setenv("PORT", "9090")
	t.Setenv("DATABASE_URL", "postgresql://user:pass@localhost:5432/testdb?sslmode=disable")
	t.Setenv("READ_REPLICA_DSN", "postgresql://replica:pass@localhost:5432/testdb?sslmode=disable")
	t.Setenv("ADMIN_DB_STORAGE_PATH", "/tmp/admin-databases")
	t.Setenv("SEARCH_BACKEND", "opensearch")
	t.Setenv("ANALYTICS_LAKE", "object_storage_spark")
	t.Setenv("ELASTICSEARCH_URL", "http://elasticsearch:9200")
	t.Setenv("OPENSEARCH_URL", "http://opensearch:9200")
	t.Setenv("ANALYTICS_LAKE_URI", "s3://analytics-lake")
	t.Setenv("SPARK_MASTER_URL", "spark://spark-master:7077")
	t.Setenv("REDIS_ADDR", "redis:6379")
	t.Setenv("REDIS_PASSWORD", "secret")
	t.Setenv("REDIS_DB", "3")
	t.Setenv("CLICKHOUSE_ADDR", "clickhouse:9000")
	t.Setenv("CLICKHOUSE_DB", "search")
	t.Setenv("CLICKHOUSE_USER", "default")
	t.Setenv("CLICKHOUSE_PASSWORD", "clicksecret")
	t.Setenv("ENABLE_CDC", "false")
	t.Setenv("ENABLE_DB_SEARCH", "false")
	t.Setenv("JWT_SECRET", "test-secret")

	cfg := LoadConfig()

	if cfg.Port != "9090" {
		t.Fatalf("expected port 9090, got %q", cfg.Port)
	}
	if cfg.DatabaseURL != "postgresql://user:pass@localhost:5432/testdb?sslmode=disable" {
		t.Fatalf("unexpected database url: %q", cfg.DatabaseURL)
	}
	if cfg.ReadReplicaDSN != "postgresql://replica:pass@localhost:5432/testdb?sslmode=disable" {
		t.Fatalf("unexpected replica dsn: %q", cfg.ReadReplicaDSN)
	}
	if cfg.AdminDBStoragePath != "/tmp/admin-databases" {
		t.Fatalf("unexpected admin db storage path: %q", cfg.AdminDBStoragePath)
	}
	if cfg.SearchBackend != "opensearch" {
		t.Fatalf("unexpected search backend: %q", cfg.SearchBackend)
	}
	if cfg.AnalyticsLake != "object_storage_spark" {
		t.Fatalf("unexpected analytics lake mode: %q", cfg.AnalyticsLake)
	}
	if cfg.ElasticsearchURL != "http://elasticsearch:9200" || cfg.OpenSearchURL != "http://opensearch:9200" {
		t.Fatalf("unexpected search urls: %+v", cfg)
	}
	if cfg.AnalyticsLakeURI != "s3://analytics-lake" || cfg.SparkMasterURL != "spark://spark-master:7077" {
		t.Fatalf("unexpected analytics lake settings: %+v", cfg)
	}
	if cfg.RedisAddr != "redis:6379" || cfg.RedisPassword != "secret" || cfg.RedisDB != 3 {
		t.Fatalf("unexpected redis settings: %+v", cfg)
	}
	if cfg.ClickHouseAddr != "clickhouse:9000" || cfg.ClickHouseDB != "search" || cfg.ClickHouseUser != "default" || cfg.ClickHousePassword != "clicksecret" {
		t.Fatalf("unexpected clickhouse settings: %+v", cfg)
	}
	if cfg.EnableCDC {
		t.Fatal("expected CDC to be disabled")
	}
	if cfg.EnableDBSearch {
		t.Fatal("expected DB search to be disabled")
	}
	if cfg.JWTSecret != "test-secret" {
		t.Fatalf("unexpected JWT secret: %q", cfg.JWTSecret)
	}
	if cfg.ClickHouseDSN == "" {
		t.Fatal("expected ClickHouse DSN to be constructed")
	}
}
