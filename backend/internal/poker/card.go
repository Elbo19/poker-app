package poker

import (
	"fmt"
	"sort"
	"strings"
)

// Card represents a playing card with rank and suit
type Card struct {
	Rank int    // 2-14 (2-10, Jack=11, Queen=12, King=13, Ace=14)
	Suit string // H, D, C, S
}

// ParseCard converts a string like "HA" to a Card
func ParseCard(s string) (Card, error) {
	if len(s) != 2 {
		return Card{}, fmt.Errorf("invalid card format: %s", s)
	}

	suit := strings.ToUpper(string(s[0]))
	rankChar := strings.ToUpper(string(s[1]))

	// Validate suit
	if !strings.Contains("HDCS", suit) {
		return Card{}, fmt.Errorf("invalid suit: %s", suit)
	}

	// Parse rank
	var rank int
	switch rankChar {
	case "2", "3", "4", "5", "6", "7", "8", "9":
		rank = int(rankChar[0] - '0')
	case "T":
		rank = 10
	case "J":
		rank = 11
	case "Q":
		rank = 12
	case "K":
		rank = 13
	case "A":
		rank = 14
	default:
		return Card{}, fmt.Errorf("invalid rank: %s", rankChar)
	}

	return Card{Rank: rank, Suit: suit}, nil
}

// ParseCards parses a slice of card strings
func ParseCards(cards []string) ([]Card, error) {
	result := make([]Card, len(cards))
	for i, cardStr := range cards {
		card, err := ParseCard(cardStr)
		if err != nil {
			return nil, err
		}
		result[i] = card
	}
	return result, nil
}

// String returns the string representation of a card
func (c Card) String() string {
	suitMap := map[string]string{"H": "♥", "D": "♦", "C": "♣", "S": "♠"}
	rankMap := map[int]string{
		2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9",
		10: "T", 11: "J", 12: "Q", 13: "K", 14: "A",
	}
	return fmt.Sprintf("%s%s", suitMap[c.Suit], rankMap[c.Rank])
}

// SortCards sorts cards by rank in descending order
func SortCards(cards []Card) []Card {
	sorted := make([]Card, len(cards))
	copy(sorted, cards)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].Rank > sorted[j].Rank
	})
	return sorted
}
