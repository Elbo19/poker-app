package poker

import (
	"testing"
)

func TestParseCard(t *testing.T) {
	tests := []struct {
		input    string
		expected Card
		hasError bool
	}{
		{"HA", Card{Rank: 14, Suit: "H"}, false},
		{"S7", Card{Rank: 7, Suit: "S"}, false},
		{"CT", Card{Rank: 10, Suit: "C"}, false},
		{"DJ", Card{Rank: 11, Suit: "D"}, false},
		{"HQ", Card{Rank: 12, Suit: "H"}, false},
		{"SK", Card{Rank: 13, Suit: "S"}, false},
		{"C2", Card{Rank: 2, Suit: "C"}, false},
		{"invalid", Card{}, true},
		{"H", Card{}, true},
		{"H1", Card{}, true},
		{"XA", Card{}, true},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			card, err := ParseCard(tt.input)
			if tt.hasError {
				if err == nil {
					t.Errorf("Expected error for input %s, but got none", tt.input)
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error for input %s: %v", tt.input, err)
				}
				if card.Rank != tt.expected.Rank || card.Suit != tt.expected.Suit {
					t.Errorf("For input %s, expected %+v, got %+v", tt.input, tt.expected, card)
				}
			}
		})
	}
}

func TestEvaluateHand_RoyalFlush(t *testing.T) {
	cards, _ := ParseCards([]string{"HA", "HK", "HQ", "HJ", "HT"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != RoyalFlush {
		t.Errorf("Expected Royal Flush, got %s", hand.Rank)
	}
}

func TestEvaluateHand_StraightFlush(t *testing.T) {
	cards, _ := ParseCards([]string{"D9", "D8", "D7", "D6", "D5"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != StraightFlush {
		t.Errorf("Expected Straight Flush, got %s", hand.Rank)
	}
}

func TestEvaluateHand_FourOfAKind(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HA", "DA", "CA", "SK"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != FourOfAKind {
		t.Errorf("Expected Four of a Kind, got %s", hand.Rank)
	}
}

func TestEvaluateHand_FullHouse(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HA", "DA", "CK", "SK"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != FullHouse {
		t.Errorf("Expected Full House, got %s", hand.Rank)
	}
}

func TestEvaluateHand_Flush(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "SK", "SQ", "S9", "S7"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != Flush {
		t.Errorf("Expected Flush, got %s", hand.Rank)
	}
}

func TestEvaluateHand_Straight(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HK", "DQ", "CJ", "ST"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != Straight {
		t.Errorf("Expected Straight, got %s", hand.Rank)
	}
}

func TestEvaluateHand_Straight_Wheel(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "H2", "D3", "C4", "S5"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != Straight {
		t.Errorf("Expected Straight (wheel), got %s", hand.Rank)
	}
}

func TestEvaluateHand_ThreeOfAKind(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HA", "DA", "CK", "SQ"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != ThreeOfAKind {
		t.Errorf("Expected Three of a Kind, got %s", hand.Rank)
	}
}

func TestEvaluateHand_TwoPair(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HA", "DK", "CK", "SQ"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != TwoPair {
		t.Errorf("Expected Two Pair, got %s", hand.Rank)
	}
}

func TestEvaluateHand_OnePair(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HA", "DK", "CQ", "SJ"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != OnePair {
		t.Errorf("Expected One Pair, got %s", hand.Rank)
	}
}

func TestEvaluateHand_HighCard(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HK", "DQ", "CJ", "S9"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != HighCard {
		t.Errorf("Expected High Card, got %s", hand.Rank)
	}
}

func TestEvaluateHand_SevenCards(t *testing.T) {
	cards, _ := ParseCards([]string{"SA", "HA", "DK", "CK", "SQ", "H3", "D2"})
	hand, err := EvaluateHand(cards)

	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if hand.Rank != TwoPair {
		t.Errorf("Expected Two Pair, got %s", hand.Rank)
	}
}

func TestCompareHands(t *testing.T) {
	tests := []struct {
		name     string
		hand1    []string
		hand2    []string
		expected int
	}{
		{
			name:     "Royal Flush beats Straight Flush",
			hand1:    []string{"HA", "HK", "HQ", "HJ", "HT"},
			hand2:    []string{"D9", "D8", "D7", "D6", "D5"},
			expected: 1,
		},
		{
			name:     "Four of a Kind beats Full House",
			hand1:    []string{"SA", "HA", "DA", "CA", "SK"},
			hand2:    []string{"SQ", "HQ", "DQ", "CK", "SK"},
			expected: 1,
		},
		{
			name:     "Full House beats Flush",
			hand1:    []string{"SA", "HA", "DA", "CK", "SK"},
			hand2:    []string{"S2", "S4", "S6", "S8", "ST"},
			expected: 1,
		},
		{
			name:     "Higher pair wins",
			hand1:    []string{"SA", "HA", "DK", "CQ", "SJ"},
			hand2:    []string{"SK", "HK", "DQ", "CJ", "ST"},
			expected: 1,
		},
		{
			name:     "Tie with same hand",
			hand1:    []string{"SA", "HK", "DQ", "CJ", "S9"},
			hand2:    []string{"HA", "DK", "CQ", "SJ", "H9"},
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cards1, _ := ParseCards(tt.hand1)
			cards2, _ := ParseCards(tt.hand2)

			hand1, _ := EvaluateHand(cards1)
			hand2, _ := EvaluateHand(cards2)

			result := hand1.Compare(hand2)
			if result != tt.expected {
				t.Errorf("Expected %d, got %d. Hand1: %s, Hand2: %s",
					tt.expected, result, hand1.Description, hand2.Description)
			}
		})
	}
}
