package poker

import (
	"fmt"
	"math/rand"
	"time"
)

// ProbabilityResult holds the result of a Monte Carlo simulation
type ProbabilityResult struct {
	WinProbability  float64 `json:"winProbability"`
	TieProbability  float64 `json:"tieProbability"`
	LossProbability float64 `json:"lossProbability"`
	Simulations     int     `json:"simulations"`
}

// CalculateWinProbability calculates the probability of winning using Monte Carlo simulation
func CalculateWinProbability(holeCards []Card, communityCards []Card, numPlayers int, numSimulations int) (*ProbabilityResult, error) {
	if len(holeCards) != 2 {
		return nil, fmt.Errorf("must have exactly 2 hole cards")
	}
	if len(communityCards) > 5 {
		return nil, fmt.Errorf("cannot have more than 5 community cards")
	}
	if numPlayers < 2 || numPlayers > 10 {
		return nil, fmt.Errorf("number of players must be between 2 and 10")
	}
	if numSimulations < 1 {
		return nil, fmt.Errorf("number of simulations must be at least 1")
	}

	// Create a deck and remove known cards
	usedCards := make(map[string]bool)
	for _, card := range holeCards {
		usedCards[fmt.Sprintf("%d%s", card.Rank, card.Suit)] = true
	}
	for _, card := range communityCards {
		usedCards[fmt.Sprintf("%d%s", card.Rank, card.Suit)] = true
	}

	// Build available deck
	availableDeck := []Card{}
	suits := []string{"H", "D", "C", "S"}
	for _, suit := range suits {
		for rank := 2; rank <= 14; rank++ {
			key := fmt.Sprintf("%d%s", rank, suit)
			if !usedCards[key] {
				availableDeck = append(availableDeck, Card{Rank: rank, Suit: suit})
			}
		}
	}

	wins := 0
	ties := 0
	losses := 0

	// Seed random number generator
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	// Run simulations
	for sim := 0; sim < numSimulations; sim++ {
		result := simulateHand(holeCards, communityCards, availableDeck, numPlayers, rng)
		switch result {
		case 1:
			wins++
		case 0:
			ties++
		case -1:
			losses++
		}
	}

	total := float64(numSimulations)
	return &ProbabilityResult{
		WinProbability:  float64(wins) / total,
		TieProbability:  float64(ties) / total,
		LossProbability: float64(losses) / total,
		Simulations:     numSimulations,
	}, nil
}

// simulateHand simulates one hand and returns 1 for win, 0 for tie, -1 for loss
func simulateHand(holeCards []Card, communityCards []Card, availableDeck []Card, numPlayers int, rng *rand.Rand) int {
	// Shuffle available deck
	deck := make([]Card, len(availableDeck))
	copy(deck, availableDeck)
	shuffleDeck(deck, rng)

	deckIdx := 0

	// Complete community cards if needed
	fullCommunity := make([]Card, len(communityCards))
	copy(fullCommunity, communityCards)
	cardsNeeded := 5 - len(communityCards)
	for i := 0; i < cardsNeeded; i++ {
		fullCommunity = append(fullCommunity, deck[deckIdx])
		deckIdx++
	}

	// Evaluate player's hand
	playerCards := append(holeCards, fullCommunity...)
	playerHand, err := EvaluateHand(playerCards)
	if err != nil {
		return -1 // Should not happen
	}

	// Deal and evaluate opponent hands
	opponentHands := make([]*Hand, numPlayers-1)
	for i := 0; i < numPlayers-1; i++ {
		opponentHoleCards := []Card{deck[deckIdx], deck[deckIdx+1]}
		deckIdx += 2

		opponentCards := append(opponentHoleCards, fullCommunity...)
		opponentHand, err := EvaluateHand(opponentCards)
		if err != nil {
			return -1 // Should not happen
		}
		opponentHands[i] = opponentHand
	}

	// Determine result
	wins := 0
	ties := 0

	for _, opponentHand := range opponentHands {
		cmp := playerHand.Compare(opponentHand)
		if cmp > 0 {
			wins++
		} else if cmp == 0 {
			ties++
		}
	}

	// Player wins if they beat all opponents
	if wins == len(opponentHands) {
		return 1
	}

	// Tie if tied with at least one opponent and not beaten by any
	if ties > 0 && wins+ties == len(opponentHands) {
		return 0
	}

	// Otherwise loss
	return -1
}

// shuffleDeck shuffles the deck in place using Fisher-Yates algorithm
func shuffleDeck(deck []Card, rng *rand.Rand) {
	for i := len(deck) - 1; i > 0; i-- {
		j := rng.Intn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}
}
