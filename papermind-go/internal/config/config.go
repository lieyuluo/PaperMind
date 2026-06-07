package config

type Config struct {
	Server   ServerConfig   `yaml:"server"`
	Postgres PostgresConfig `yaml:"postgres"`
	Qdrant   QdrantConfig   `yaml:"qdrant"`
	Minio    MinioConfig    `yaml:"minio"`
	Temporal TemporalConfig `yaml:"temporal"`
	LLM      LLMConfig      `yaml:"llm"`
	JWT      JWTConfig      `yaml:"jwt"`
}

type ServerConfig struct {
	Address string `yaml:"address"`
	Mode    string `yaml:"mode"`
}

type PostgresConfig struct {
	DSN string `yaml:"dsn"`
}

type QdrantConfig struct {
	Address         string `yaml:"address"`
	HTTPAddress     string `yaml:"http_address"`
	ChunkCollection string `yaml:"chunk_collection"`
	LogicCollection string `yaml:"logic_collection"`
}

type MinioConfig struct {
	Endpoint  string `yaml:"endpoint"`
	AccessKey string `yaml:"access_key"`
	SecretKey string `yaml:"secret_key"`
	Bucket    string `yaml:"bucket"`
	UseSSL    bool   `yaml:"use_ssl"`
}

type TemporalConfig struct {
	Address   string `yaml:"address"`
	Namespace string `yaml:"namespace"`
	TaskQueue string `yaml:"task_queue"`
}

type LLMConfig struct {
	Provider       string `yaml:"provider"`
	BaseURL        string `yaml:"base_url"`
	APIKey         string `yaml:"api_key"`
	ChatModel      string `yaml:"chat_model"`
	EmbeddingModel string `yaml:"embedding_model"`
}

type JWTConfig struct {
	Secret       string `yaml:"secret"`
	ExpireSeconds int    `yaml:"expire_seconds"`
}
