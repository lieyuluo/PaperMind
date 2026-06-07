package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("PaperMind Migration - use 'make migrate-up' or 'make migrate-down' instead")
	fmt.Println("Migrations are managed via psql and SQL files in migrations/")
	os.Exit(0)
}
