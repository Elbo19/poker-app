package handler

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"poker-app/internal/poker"
)

// EnableCORS wraps a handler to add CORS headers
func EnableCORS(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		handler(w, r)
	}
}

// RootHandler handles requests to the root path
func RootHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"name":    "Texas Hold'em Poker API",
		"version": "1.0.0",
		"endpoints": map[string]string{
			"GET /health":           "Health check",
			"POST /api/evaluate":    "Evaluate poker hand",
			"POST /api/compare":     "Compare two poker hands",
			"POST /api/probability": "Calculate win probability",
		},
		"documentation": "See README.md for API details",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// HealthHandler handles health check requests
func HealthHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status":  "healthy",
		"version": "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// EvaluateRequest represents the request body for /api/evaluate
type EvaluateRequest struct {
	HoleCards      []string `json:"holeCards"`
	CommunityCards []string `json:"communityCards"`
}

// EvaluateResponse represents the response for /api/evaluate
type EvaluateResponse struct {
	HandRank    string   `json:"handRank"`
	Description string   `json:"description"`
	Cards       []string `json:"cards"`
	Success     bool     `json:"success"`
	Error       string   `json:"error,omitempty"`
}

// EvaluateHandler handles hand evaluation requests
func EvaluateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req EvaluateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Parse hole cards
	holeCards, err := poker.ParseCards(req.HoleCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid hole cards: %v", err), http.StatusBadRequest)
		return
	}

	// Parse community cards
	communityCards, err := poker.ParseCards(req.CommunityCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid community cards: %v", err), http.StatusBadRequest)
		return
	}

	// Combine all cards
	allCards := append(holeCards, communityCards...)
	if len(allCards) < 5 {
		sendError(w, "Need at least 5 cards total", http.StatusBadRequest)
		return
	}

	// Evaluate hand
	hand, err := poker.EvaluateHand(allCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Error evaluating hand: %v", err), http.StatusInternalServerError)
		return
	}

	// Build response
	cardStrings := make([]string, len(hand.Cards))
	for i, card := range hand.Cards {
		cardStrings[i] = card.String()
	}

	response := EvaluateResponse{
		HandRank:    hand.Rank.String(),
		Description: hand.Description,
		Cards:       cardStrings,
		Success:     true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// CompareRequest represents the request body for /api/compare
type CompareRequest struct {
	Player1HoleCards      []string `json:"player1HoleCards"`
	Player1CommunityCards []string `json:"player1CommunityCards"`
	Player2HoleCards      []string `json:"player2HoleCards"`
	Player2CommunityCards []string `json:"player2CommunityCards"`
}

// CompareResponse represents the response for /api/compare
type CompareResponse struct {
	Player1Hand        string `json:"player1Hand"`
	Player1Description string `json:"player1Description"`
	Player2Hand        string `json:"player2Hand"`
	Player2Description string `json:"player2Description"`
	Winner             string `json:"winner"`
	Success            bool   `json:"success"`
	Error              string `json:"error,omitempty"`
}

// CompareHandler handles hand comparison requests
func CompareHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req CompareRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Parse player 1 cards
	p1HoleCards, err := poker.ParseCards(req.Player1HoleCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid player 1 hole cards: %v", err), http.StatusBadRequest)
		return
	}
	p1CommunityCards, err := poker.ParseCards(req.Player1CommunityCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid player 1 community cards: %v", err), http.StatusBadRequest)
		return
	}

	// Parse player 2 cards
	p2HoleCards, err := poker.ParseCards(req.Player2HoleCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid player 2 hole cards: %v", err), http.StatusBadRequest)
		return
	}
	p2CommunityCards, err := poker.ParseCards(req.Player2CommunityCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid player 2 community cards: %v", err), http.StatusBadRequest)
		return
	}

	// Evaluate both hands
	p1AllCards := append(p1HoleCards, p1CommunityCards...)
	p2AllCards := append(p2HoleCards, p2CommunityCards...)

	if len(p1AllCards) < 5 || len(p2AllCards) < 5 {
		sendError(w, "Each player needs at least 5 cards total", http.StatusBadRequest)
		return
	}

	hand1, err := poker.EvaluateHand(p1AllCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Error evaluating player 1 hand: %v", err), http.StatusInternalServerError)
		return
	}

	hand2, err := poker.EvaluateHand(p2AllCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Error evaluating player 2 hand: %v", err), http.StatusInternalServerError)
		return
	}

	// Compare hands
	result := hand1.Compare(hand2)
	var winner string
	switch result {
	case 1:
		winner = "player1"
	case -1:
		winner = "player2"
	case 0:
		winner = "tie"
	}

	response := CompareResponse{
		Player1Hand:        hand1.Rank.String(),
		Player1Description: hand1.Description,
		Player2Hand:        hand2.Rank.String(),
		Player2Description: hand2.Description,
		Winner:             winner,
		Success:            true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// ProbabilityRequest represents the request body for /api/probability
type ProbabilityRequest struct {
	HoleCards      []string `json:"holeCards"`
	CommunityCards []string `json:"communityCards"`
	NumPlayers     int      `json:"numPlayers"`
	Simulations    int      `json:"simulations"`
}

// ProbabilityResponse represents the response for /api/probability
type ProbabilityResponse struct {
	WinProbability  float64 `json:"winProbability"`
	TieProbability  float64 `json:"tieProbability"`
	LossProbability float64 `json:"lossProbability"`
	Simulations     int     `json:"simulations"`
	Success         bool    `json:"success"`
	Error           string  `json:"error,omitempty"`
}

// ProbabilityHandler handles win probability calculation requests
func ProbabilityHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ProbabilityRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Parse cards
	holeCards, err := poker.ParseCards(req.HoleCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid hole cards: %v", err), http.StatusBadRequest)
		return
	}

	communityCards, err := poker.ParseCards(req.CommunityCards)
	if err != nil {
		sendError(w, fmt.Sprintf("Invalid community cards: %v", err), http.StatusBadRequest)
		return
	}

	// Calculate probability
	result, err := poker.CalculateWinProbability(holeCards, communityCards, req.NumPlayers, req.Simulations)
	if err != nil {
		sendError(w, fmt.Sprintf("Error calculating probability: %v", err), http.StatusBadRequest)
		return
	}

	log.Printf("Probability calculation: Win=%.2f%%, Tie=%.2f%%, Loss=%.2f%%",
		result.WinProbability*100, result.TieProbability*100, result.LossProbability*100)

	response := ProbabilityResponse{
		WinProbability:  result.WinProbability,
		TieProbability:  result.TieProbability,
		LossProbability: result.LossProbability,
		Simulations:     result.Simulations,
		Success:         true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// sendError sends an error response
func sendError(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": false,
		"error":   message,
	})
}
