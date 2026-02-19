import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PokerApp());
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas Hold\'em Poker Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFF0A1929),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF00E5FF),
          surface: const Color(0xFF1C2833),
          background: const Color(0xFF0A1929),
        ),
        cardTheme: const CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          color: Color(0xFF1C2833),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: const Color(0xFF0A1929),
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 3),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      home: const PokerHomePage(),
    );
  }
}

class PokerHomePage extends StatefulWidget {
  const PokerHomePage({super.key});

  @override
  State<PokerHomePage> createState() => _PokerHomePageState();
}

// Playing Card Widget
class PlayingCard extends StatelessWidget {
  final String? rank;
  final String? suit;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PlayingCard({
    super.key,
    this.rank,
    this.suit,
    this.width = 80,
    this.height = 112,
    this.onTap,
  });

  Color get suitColor {
    if (suit == null) return Colors.black;
    switch (suit!.toUpperCase()) {
      case 'H':
      case 'D':
        return const Color(0xFFDC143C);
      case 'C':
      case 'S':
        return Colors.black87;
      default:
        return Colors.black;
    }
  }

  String get suitSymbol {
    if (suit == null) return '';
    switch (suit!.toUpperCase()) {
      case 'H': return '♥';
      case 'D': return '♦';
      case 'C': return '♣';
      case 'S': return '♠';
      default: return suit!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = rank == null || suit == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isEmpty ? const Color(0xFF1C2833) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEmpty ? const Color(0xFF00E5FF).withOpacity(0.3) : const Color(0xFF00E5FF),
            width: isEmpty ? 1 : 2,
          ),
          boxShadow: isEmpty ? null : [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isEmpty
            ? Center(
                child: Icon(
                  Icons.add,
                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                  size: 32,
                ),
              )
            : Column(
                children: [
                  // Top rank and suit
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rank!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: suitColor,
                              height: 1,
                            ),
                          ),
                          Text(
                            suitSymbol,
                            style: TextStyle(
                              fontSize: 20,
                              color: suitColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Center large suit
                  Expanded(
                    child: Center(
                      child: Text(
                        suitSymbol,
                        style: TextStyle(
                          fontSize: 40,
                          color: suitColor,
                        ),
                      ),
                    ),
                  ),
                  // Bottom rank and suit (rotated)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Transform.rotate(
                        angle: 3.14159,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rank!,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: suitColor,
                                height: 1,
                              ),
                            ),
                            Text(
                              suitSymbol,
                              style: TextStyle(
                                fontSize: 20,
                                color: suitColor,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum PokerMode { evaluate, compare, probability }

class _PokerHomePageState extends State<PokerHomePage> {
  // Use localhost for development, GKE IP for production
  final String apiUrl = kDebugMode 
      ? 'http://localhost:8080'
      : 'http://136.113.179.68';
  
  // Current mode
  PokerMode _mode = PokerMode.compare;
  
  // Single player hole cards (for evaluate and probability modes)
  final TextEditingController _holeCard1Controller = TextEditingController();
  final TextEditingController _holeCard2Controller = TextEditingController();
  
  // Player 1 hole cards (for compare mode)
  final TextEditingController _p1HoleCard1Controller = TextEditingController();
  final TextEditingController _p1HoleCard2Controller = TextEditingController();
  
  // Player 2 hole cards (for compare mode)
  final TextEditingController _p2HoleCard1Controller = TextEditingController();
  final TextEditingController _p2HoleCard2Controller = TextEditingController();
  
  // Community cards
  final TextEditingController _flop1Controller = TextEditingController();
  final TextEditingController _flop2Controller = TextEditingController();
  final TextEditingController _flop3Controller = TextEditingController();
  final TextEditingController _turnController = TextEditingController();
  final TextEditingController _riverController = TextEditingController();
  
  // Probability mode settings
  final TextEditingController _numPlayersController = TextEditingController(text: '6');
  final TextEditingController _simulationsController = TextEditingController(text: '10000');
  
  // Results
  String _result = '';
  String _player1Hand = '';
  String _player2Hand = '';
  List<String> _player1Cards = [];
  List<String> _player2Cards = [];
  String _winner = '';
  String _evaluatedHand = '';
  String _evaluatedHandRank = '';
  List<String> _evaluatedCards = [];
  double _winProbability = 0.0;
  double _tieProbability = 0.0;
  double _lossProbability = 0.0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to trigger rebuild when cards change
    _holeCard1Controller.addListener(() => setState(() {}));
    _holeCard2Controller.addListener(() => setState(() {}));
    _p1HoleCard1Controller.addListener(() => setState(() {}));
    _p1HoleCard2Controller.addListener(() => setState(() {}));
    _p2HoleCard1Controller.addListener(() => setState(() {}));
    _p2HoleCard2Controller.addListener(() => setState(() {}));
    _flop1Controller.addListener(() => setState(() {}));
    _flop2Controller.addListener(() => setState(() {}));
    _flop3Controller.addListener(() => setState(() {}));
    _turnController.addListener(() => setState(() {}));
    _riverController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _holeCard1Controller.dispose();
    _holeCard2Controller.dispose();
    _p1HoleCard1Controller.dispose();
    _p1HoleCard2Controller.dispose();
    _p2HoleCard1Controller.dispose();
    _p2HoleCard2Controller.dispose();
    _flop1Controller.dispose();
    _flop2Controller.dispose();
    _flop3Controller.dispose();
    _turnController.dispose();
    _riverController.dispose();
    _numPlayersController.dispose();
    _simulationsController.dispose();
    super.dispose();
  }

  // Helper method to get suit symbol
  String getSuitSymbol(String suit) {
    switch (suit.toUpperCase()) {
      case 'H': return '♥';
      case 'D': return '♦';
      case 'C': return '♣';
      case 'S': return '♠';
      default: return suit;
    }
  }

  // Helper method to get suit color
  Color getSuitColor(String suit) {
    switch (suit.toUpperCase()) {
      case 'H':
      case 'D':
        return Colors.red;
      case 'C':
      case 'S':
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  // Helper method to parse card text (e.g., "HA" -> rank: "A", suit: "H")
  Map<String, String>? parseCard(String cardText) {
    if (cardText.isEmpty || cardText.length < 2) return null;
    return {
      'suit': cardText[0].toUpperCase(),
      'rank': cardText[1].toUpperCase(),
    };
  }

  // Show error dialog with appropriate message
  void _showErrorDialog(String title, String message, {IconData? icon}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2833),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF44336), width: 2),
          ),
          title: Row(
            children: [
              Icon(
                icon ?? Icons.error_outline,
                color: const Color(0xFFF44336),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF44336),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0A1929),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Validate card format
  bool _isValidCard(String card) {
    if (card.isEmpty) return true; // Empty is ok for community cards
    if (card.length != 2) return false;
    
    final suit = card[0].toUpperCase();
    final rank = card[1].toUpperCase();
    
    final validSuits = ['H', 'D', 'C', 'S'];
    final validRanks = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'];
    
    return validSuits.contains(suit) && validRanks.contains(rank);
  }

  // Validate hole cards are provided
  bool _validateHoleCards(TextEditingController card1, TextEditingController card2, {String playerName = ''}) {
    if (card1.text.isEmpty || card2.text.isEmpty) {
      _showErrorDialog(
        'Missing Cards',
        '${playerName.isEmpty ? "Both" : "$playerName"} hole cards are required.',
        icon: Icons.credit_card_off,
      );
      return false;
    }
    
    if (!_isValidCard(card1.text) || !_isValidCard(card2.text)) {
      _showErrorDialog(
        'Invalid Card Format',
        'Cards must be 2 characters: first letter is suit (H/D/C/S), second is rank (2-9/T/J/Q/K/A).\nExample: HA (Heart Ace), S7 (Spade 7)',
        icon: Icons.format_clear,
      );
      return false;
    }
    
    return true;
  }

  // Validate community cards format
  bool _validateCommunityCards() {
    final cards = [
      _flop1Controller.text,
      _flop2Controller.text,
      _flop3Controller.text,
      _turnController.text,
      _riverController.text,
    ];
    
    for (final card in cards) {
      if (!_isValidCard(card)) {
        _showErrorDialog(
          'Invalid Card Format',
          'Invalid community card: "$card"\nCards must be 2 characters: first letter is suit (H/D/C/S), second is rank (2-9/T/J/Q/K/A)',
          icon: Icons.format_clear,
        );
        return false;
      }
    }
    
    return true;
  }

  Future<void> compareHands() async {
    // Validate inputs
    if (!_validateHoleCards(_p1HoleCard1Controller, _p1HoleCard2Controller, playerName: 'Player 1')) {
      return;
    }
    if (!_validateHoleCards(_p2HoleCard1Controller, _p2HoleCard2Controller, playerName: 'Player 2')) {
      return;
    }
    if (!_validateCommunityCards()) {
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
      _player1Hand = '';
      _player2Hand = '';
      _winner = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'player1HoleCards': [_p1HoleCard1Controller.text.toUpperCase(), _p1HoleCard2Controller.text.toUpperCase()],
          'player1CommunityCards': [
            _flop1Controller.text,
            _flop2Controller.text,
            _flop3Controller.text,
            _turnController.text,
            _riverController.text,
          ].where((c) => c.isNotEmpty).map((c) => c.toUpperCase()).toList(),
          'player2HoleCards': [_p2HoleCard1Controller.text.toUpperCase(), _p2HoleCard2Controller.text.toUpperCase()],
          'player2CommunityCards': [
            _flop1Controller.text,
            _flop2Controller.text,
            _flop3Controller.text,
            _turnController.text,
            _riverController.text,
          ].where((c) => c.isNotEmpty).map((c) => c.toUpperCase()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _player1Hand = data['player1Description'] ?? 'Unknown hand';
            _player2Hand = data['player2Description'] ?? 'Unknown hand';
            _player1Cards = List<String>.from(data['player1Cards'] ?? []);
            _player2Cards = List<String>.from(data['player2Cards'] ?? []);
            _winner = data['winner'];
            
            String winnerText;
            if (_winner == 'player1') {
              winnerText = '🏆 PLAYER 1 WINS!';
            } else if (_winner == 'player2') {
              winnerText = '🏆 PLAYER 2 WINS!';
            } else {
              winnerText = '🤝 TIE - SPLIT POT!';
            }
            
            _result = winnerText;
          });
        } else {
          setState(() {
            _result = '';
            _player1Hand = '';
            _player2Hand = '';
            _player1Cards = [];
            _player2Cards = [];
            _winner = '';
          });
          _showErrorDialog(
            'Comparison Failed',
            data['error'] ?? 'Unknown error occurred',
            icon: Icons.error,
          );
        }
      } else if (response.statusCode == 400) {
        setState(() {
          _result = '';
          _player1Hand = '';
          _player2Hand = '';
          _player1Cards = [];
          _player2Cards = [];
          _winner = '';
        });
        final data = jsonDecode(response.body);
        _showErrorDialog(
          'Invalid Input',
          data['error'] ?? 'Invalid card data provided',
          icon: Icons.warning,
        );
      } else if (response.statusCode >= 500) {
        setState(() {
          _result = '';
          _player1Hand = '';
          _player2Hand = '';
          _player1Cards = [];
          _player2Cards = [];
          _winner = '';
        });
        _showErrorDialog(
          'Server Error',
          'The server encountered an error. Please try again later.',
          icon: Icons.cloud_off,
        );
      } else {
        setState(() {
          _result = '';
          _player1Hand = '';
          _player2Hand = '';
          _player1Cards = [];
          _player2Cards = [];
          _winner = '';
        });
        _showErrorDialog(
          'Request Failed',
          'Unable to process your request. Please check your input and try again.',
          icon: Icons.error_outline,
        );
      }
    } on http.ClientException {
      setState(() {
        _result = '';
        _player1Hand = '';
        _player2Hand = '';
        _player1Cards = [];
        _player2Cards = [];
        _winner = '';
      });
      _showErrorDialog(
        'Connection Failed',
        'Cannot connect to server. Please check your internet connection.',
        icon: Icons.wifi_off,
      );
    } on FormatException {
      setState(() {
        _result = '';
        _player1Hand = '';
        _player2Hand = '';
        _player1Cards = [];
        _player2Cards = [];
        _winner = '';
      });
      _showErrorDialog(
        'Invalid Response',
        'Received invalid data from server. Please try again.',
        icon: Icons.data_usage,
      );
    } catch (e) {
      setState(() {
        _result = '';
        _player1Hand = '';
        _player2Hand = '';
        _player1Cards = [];
        _player2Cards = [];
        _winner = '';
      });
      _showErrorDialog(
        'Unexpected Error',
        'Something went wrong. Please try again or contact support if the problem persists.',
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> evaluateHand() async {
    // Validate inputs
    if (!_validateHoleCards(_holeCard1Controller, _holeCard2Controller)) {
      return;
    }
    if (!_validateCommunityCards()) {
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
      _evaluatedHand = '';
      _evaluatedHandRank = '';
      _evaluatedCards = [];
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'holeCards': [_holeCard1Controller.text.toUpperCase(), _holeCard2Controller.text.toUpperCase()],
          'communityCards': [
            _flop1Controller.text,
            _flop2Controller.text,
            _flop3Controller.text,
            _turnController.text,
            _riverController.text,
          ].where((c) => c.isNotEmpty).map((c) => c.toUpperCase()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _evaluatedHandRank = data['handRank'] ?? 'Unknown';
            _evaluatedHand = data['description'] ?? 'Unknown hand';
            _evaluatedCards = List<String>.from(data['cards'] ?? []);
            _result = _evaluatedHandRank;
          });
        } else {
          setState(() {
            _result = '';
            _evaluatedHand = '';
            _evaluatedHandRank = '';
            _evaluatedCards = [];
          });
          _showErrorDialog(
            'Evaluation Failed',
            data['error'] ?? 'Unknown error occurred',
            icon: Icons.error,
          );
        }
      } else if (response.statusCode == 400) {
        setState(() {
          _result = '';
          _evaluatedHand = '';
          _evaluatedHandRank = '';
          _evaluatedCards = [];
        });
        final data = jsonDecode(response.body);
        _showErrorDialog(
          'Invalid Input',
          data['error'] ?? 'Invalid card data provided',
          icon: Icons.warning,
        );
      } else if (response.statusCode >= 500) {
        setState(() {
          _result = '';
          _evaluatedHand = '';
          _evaluatedHandRank = '';
          _evaluatedCards = [];
        });
        _showErrorDialog(
          'Server Error',
          'The server encountered an error. Please try again later.',
          icon: Icons.cloud_off,
        );
      } else {
        setState(() {
          _result = '';
          _evaluatedHand = '';
          _evaluatedHandRank = '';
          _evaluatedCards = [];
        });
        _showErrorDialog(
          'Request Failed',
          'Unable to process your request. Please check your input and try again.',
          icon: Icons.error_outline,
        );
      }
    } on http.ClientException {
      setState(() {
        _result = '';
        _evaluatedHand = '';
        _evaluatedHandRank = '';
        _evaluatedCards = [];
      });
      _showErrorDialog(
        'Connection Failed',
        'Cannot connect to server. Please check your internet connection.',
        icon: Icons.wifi_off,
      );
    } on FormatException {
      setState(() {
        _result = '';
        _evaluatedHand = '';
        _evaluatedHandRank = '';
        _evaluatedCards = [];
      });
      _showErrorDialog(
        'Invalid Response',
        'Received invalid data from server. Please try again.',
        icon: Icons.data_usage,
      );
    } catch (e) {
      setState(() {
        _result = '';
        _evaluatedHand = '';
        _evaluatedHandRank = '';
        _evaluatedCards = [];
      });
      _showErrorDialog(
        'Unexpected Error',
        'Something went wrong. Please try again or contact support if the problem persists.',
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> calculateProbability() async {
    // Validate inputs
    if (!_validateHoleCards(_holeCard1Controller, _holeCard2Controller)) {
      return;
    }
    if (!_validateCommunityCards()) {
      return;
    }

    // Validate settings
    final numPlayers = int.tryParse(_numPlayersController.text);
    final simulations = int.tryParse(_simulationsController.text);

    if (numPlayers == null || numPlayers < 2 || numPlayers > 10) {
      _showErrorDialog(
        'Invalid Number of Players',
        'Number of players must be between 2 and 10.',
        icon: Icons.group,
      );
      return;
    }

    if (simulations == null || simulations < 100 || simulations > 1000000) {
      _showErrorDialog(
        'Invalid Simulations',
        'Number of simulations must be between 100 and 1,000,000.',
        icon: Icons.calculate,
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
      _winProbability = 0.0;
      _tieProbability = 0.0;
      _lossProbability = 0.0;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/probability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'holeCards': [_holeCard1Controller.text.toUpperCase(), _holeCard2Controller.text.toUpperCase()],
          'communityCards': [
            _flop1Controller.text,
            _flop2Controller.text,
            _flop3Controller.text,
            _turnController.text,
            _riverController.text,
          ].where((c) => c.isNotEmpty).map((c) => c.toUpperCase()).toList(),
          'numPlayers': numPlayers,
          'simulations': simulations,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _winProbability = data['winProbability'];
            _tieProbability = data['tieProbability'];
            _lossProbability = data['lossProbability'];
            _result = 'Probability calculated with ${data['simulations']} simulations';
          });
        } else {
          setState(() {
            _result = '';
            _winProbability = 0.0;
            _tieProbability = 0.0;
            _lossProbability = 0.0;
          });
          _showErrorDialog(
            'Calculation Failed',
            data['error'] ?? 'Unknown error occurred',
            icon: Icons.error,
          );
        }
      } else if (response.statusCode == 400) {
        setState(() {
          _result = '';
          _winProbability = 0.0;
          _tieProbability = 0.0;
          _lossProbability = 0.0;
        });
        final data = jsonDecode(response.body);
        _showErrorDialog(
          'Invalid Input',
          data['error'] ?? 'Invalid card data provided',
          icon: Icons.warning,
        );
      } else if (response.statusCode >= 500) {
        setState(() {
          _result = '';
          _winProbability = 0.0;
          _tieProbability = 0.0;
          _lossProbability = 0.0;
        });
        _showErrorDialog(
          'Server Error',
          'The server encountered an error. Please try again later.',
          icon: Icons.cloud_off,
        );
      } else {
        setState(() {
          _result = '';
          _winProbability = 0.0;
          _tieProbability = 0.0;
          _lossProbability = 0.0;
        });
        _showErrorDialog(
          'Request Failed',
          'Unable to process your request. Please check your input and try again.',
          icon: Icons.error_outline,
        );
      }
    } on http.ClientException {
      setState(() {
        _result = '';
        _winProbability = 0.0;
        _tieProbability = 0.0;
        _lossProbability = 0.0;
      });
      _showErrorDialog(
        'Connection Failed',
        'Cannot connect to server. Please check your internet connection.',
        icon: Icons.wifi_off,
      );
    } on FormatException {
      setState(() {
        _result = '';
        _winProbability = 0.0;
        _tieProbability = 0.0;
        _lossProbability = 0.0;
      });
      _showErrorDialog(
        'Invalid Response',
        'Received invalid data from server. Please try again.',
        icon: Icons.data_usage,
      );
    } catch (e) {
      setState(() {
        _result = '';
        _winProbability = 0.0;
        _tieProbability = 0.0;
        _lossProbability = 0.0;
      });
      _showErrorDialog(
        'Unexpected Error',
        'Something went wrong. Please try again or contact support if the problem persists.',
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFF1565C0),
              const Color(0xFF0D47A1),
              const Color(0xFF0A1929),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),
                
                // Mode selector
                _buildModeSelector(),
                const SizedBox(height: 24),
                
                // Main poker table
                _buildPokerTable(),
                
                const SizedBox(height: 32),
                
                // Action buttons
                _buildActionButtons(),
                
                const SizedBox(height: 32),
                
                // Results display
                if (_loading)
                  _buildLoadingIndicator()
                else if (_result.isNotEmpty)
                  _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5FF),
            const Color(0xFF00BCD4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.casino, size: 40, color: Color(0xFF0A1929)),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                'TEXAS HOLD\'EM',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A1929),
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Poker Calculator',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1565C0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2833),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              'EVALUATE',
              PokerMode.evaluate,
              Icons.assessment,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildModeButton(
              'COMPARE',
              PokerMode.compare,
              Icons.compare_arrows,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildModeButton(
              'PROBABILITY',
              PokerMode.probability,
              Icons.show_chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, PokerMode mode, IconData icon) {
    final bool isSelected = _mode == mode;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _mode = mode;
          _result = '';
          _player1Hand = '';
          _player2Hand = '';
          _player1Cards = [];
          _player2Cards = [];
          _winner = '';
          _evaluatedHand = '';
          _evaluatedHandRank = '';
          _evaluatedCards = [];
          _winProbability = 0.0;
          _tieProbability = 0.0;
          _lossProbability = 0.0;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF0D1B2A),
        foregroundColor: isSelected ? const Color(0xFF0A1929) : const Color(0xFFB0BEC5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 8 : 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokerTable() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2833),
            const Color(0xFF0D1B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5FF),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_mode == PokerMode.evaluate) ...[
            // Single player mode
            _buildPlayerSection(
              playerName: 'YOUR HAND',
              card1Controller: _holeCard1Controller,
              card2Controller: _holeCard2Controller,
              color: const Color(0xFF00E5FF),
              icon: Icons.person,
            ),
          ] else if (_mode == PokerMode.compare) ...[
            // Player 1 hole cards
            _buildPlayerSection(
              playerName: 'PLAYER 1',
              card1Controller: _p1HoleCard1Controller,
              card2Controller: _p1HoleCard2Controller,
              color: const Color(0xFF00E5FF),
              icon: Icons.person,
            ),
            
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF00E5FF), thickness: 2),
            const SizedBox(height: 24),
          ] else if (_mode == PokerMode.probability) ...[
            // Single player mode for probability
            _buildPlayerSection(
              playerName: 'YOUR HAND',
              card1Controller: _holeCard1Controller,
              card2Controller: _holeCard2Controller,
              color: const Color(0xFF00E5FF),
              icon: Icons.person,
            ),
          ],
          
          // Community cards section (all modes)
          const SizedBox(height: 24),
          _buildCommunityCardsSection(),
          
          if (_mode == PokerMode.compare) ...[
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF00E5FF), thickness: 2),
            const SizedBox(height: 24),
            
            // Player 2 hole cards
            _buildPlayerSection(
              playerName: 'PLAYER 2',
              card1Controller: _p2HoleCard1Controller,
              card2Controller: _p2HoleCard2Controller,
              color: const Color(0xFFFF5722),
              icon: Icons.person_outline,
            ),
          ] else if (_mode == PokerMode.probability) ...[
            const SizedBox(height: 24),
            _buildProbabilitySettings(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerSection({
    required String playerName,
    required TextEditingController card1Controller,
    required TextEditingController card2Controller,
    required Color color,
    required IconData icon,
  }) {
    final card1 = parseCard(card1Controller.text);
    final card2 = parseCard(card2Controller.text);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              playerName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Visual cards display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlayingCard(
              rank: card1?['rank'],
              suit: card1?['suit'],
              width: 100,
              height: 140,
            ),
            const SizedBox(width: 16),
            PlayingCard(
              rank: card2?['rank'],
              suit: card2?['suit'],
              width: 100,
              height: 140,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Input fields
        Row(
          children: [
            Expanded(
              child: _buildCardInput(
                controller: card1Controller,
                label: 'CARD 1',
                hint: 'HA',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardInput(
                controller: card2Controller,
                label: 'CARD 2',
                hint: 'SK',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommunityCardsSection() {
    final flop1 = parseCard(_flop1Controller.text);
    final flop2 = parseCard(_flop2Controller.text);
    final flop3 = parseCard(_flop3Controller.text);
    final turn = parseCard(_turnController.text);
    final river = parseCard(_riverController.text);

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.style, color: Color(0xFF00E5FF), size: 24),
            const SizedBox(width: 12),
            Text(
              'COMMUNITY CARDS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00E5FF),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Visual cards display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlayingCard(rank: flop1?['rank'], suit: flop1?['suit']),
            const SizedBox(width: 8),
            PlayingCard(rank: flop2?['rank'], suit: flop2?['suit']),
            const SizedBox(width: 8),
            PlayingCard(rank: flop3?['rank'], suit: flop3?['suit']),
            const SizedBox(width: 16),
            PlayingCard(rank: turn?['rank'], suit: turn?['suit']),
            const SizedBox(width: 16),
            PlayingCard(rank: river?['rank'], suit: river?['suit']),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCardInput(
                controller: _flop1Controller,
                label: 'FLOP 1',
                hint: 'HQ',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardInput(
                controller: _flop2Controller,
                label: 'FLOP 2',
                hint: 'HJ',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardInput(
                controller: _flop3Controller,
                label: 'FLOP 3',
                hint: 'HT',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCardInput(
                controller: _turnController,
                label: 'TURN',
                hint: 'D2',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardInput(
                controller: _riverController,
                label: 'RIVER',
                hint: 'C3',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00E5FF),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.bold,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProbabilitySettings() {
    return Column(
      children: [
        const Divider(color: Color(0xFF00E5FF), thickness: 2),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFF00E5FF), size: 24),
            const SizedBox(width: 12),
            Text(
              'SIMULATION SETTINGS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00E5FF),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCardInput(
                controller: _numPlayersController,
                label: 'PLAYERS',
                hint: '2-10',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardInput(
                controller: _simulationsController,
                label: 'SIMULATIONS',
                hint: '10000',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Text(
          'Card Format: HA (♥ Ace) • S7 (♠ 7) • CT (♣ 10) • DK (♦ King)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white60,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_mode == PokerMode.evaluate)
          ElevatedButton.icon(
            onPressed: _loading ? null : evaluateHand,
            icon: const Icon(Icons.assessment, size: 32),
            label: const Text('EVALUATE HAND'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF0A1929),
              minimumSize: const Size(280, 64),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          )
        else if (_mode == PokerMode.compare)
          ElevatedButton.icon(
            onPressed: _loading ? null : compareHands,
            icon: const Icon(Icons.compare_arrows, size: 32),
            label: const Text('COMPARE HANDS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF0A1929),
              minimumSize: const Size(280, 64),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          )
        else if (_mode == PokerMode.probability)
          ElevatedButton.icon(
            onPressed: _loading ? null : calculateProbability,
            icon: const Icon(Icons.show_chart, size: 32),
            label: const Text('CALCULATE PROBABILITY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF0A1929),
              minimumSize: const Size(280, 64),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1C2833),
            const Color(0xFF0D1B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            strokeWidth: 4,
          ),
          const SizedBox(height: 24),
          Text(
            'Calculating...',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_mode == PokerMode.evaluate) {
      return _buildEvaluateResult();
    } else if (_mode == PokerMode.compare) {
      return _buildCompareResult();
    } else {
      return _buildProbabilityResult();
    }
  }

  Widget _buildEvaluateResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2833),
            const Color(0xFF0D1B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.assessment, size: 64, color: const Color(0xFF00E5FF)),
          const SizedBox(height: 16),
          Text(
            'HAND EVALUATION',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00E5FF),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          
          // Hand Rank (e.g., "Three of a Kind")
          Text(
            _evaluatedHandRank,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Best 5 Cards - Excel format style
          if (_evaluatedCards.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Best 5-Card Hand',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00E5FF),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display cards in Excel format: "DK SK HT C8 C7"
                  Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.center,
                    children: _evaluatedCards.map((card) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1929),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _convertToExcelFormat(card),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Convert card from API format (♦K) to Excel format (DK)  
  String _convertToExcelFormat(String card) {
    final suitMap = {
      '♥': 'H',
      '♦': 'D',
      '♣': 'C',
      '♠': 'S',
    };
    
    if (card.length >= 2) {
      final suit = card.substring(0, 1);
      final rank = card.substring(1);
      return '${suitMap[suit] ?? suit}$rank';
    }
    return card;
  }

  Widget _buildCompareResult() {
    Color winnerColor = _winner == 'player1' 
        ? const Color(0xFF00E5FF)
        : _winner == 'player2'
            ? const Color(0xFFFF5722)
            : const Color(0xFF4CAF50);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2833),
            const Color(0xFF0D1B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: winnerColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: winnerColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Winner announcement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  winnerColor,
                  winnerColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _winner == 'tie' ? Icons.handshake : Icons.emoji_events,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Player 1 hand
          _buildHandResult(
            playerName: 'PLAYER 1',
            handDescription: _player1Hand,
            color: const Color(0xFF00E5FF),
            isWinner: _winner == 'player1',
            cards: _player1Cards,
          ),
          
          const SizedBox(height: 24),
          
          // VS divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white30, thickness: 2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white60,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white30, thickness: 2)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Player 2 hand
          _buildHandResult(
            playerName: 'PLAYER 2',
            handDescription: _player2Hand,
            color: const Color(0xFFFF5722),
            isWinner: _winner == 'player2',
            cards: _player2Cards,
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2833),
            const Color(0xFF0D1B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.show_chart, size: 64, color: const Color(0xFF00E5FF)),
          const SizedBox(height: 16),
          Text(
            'WIN PROBABILITY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00E5FF),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          _buildProbabilityBar('WIN', _winProbability, const Color(0xFF4CAF50)),
          const SizedBox(height: 16),
          _buildProbabilityBar('TIE', _tieProbability, const Color(0xFFFFC107)),
          const SizedBox(height: 16),
          _buildProbabilityBar('LOSS', _lossProbability, const Color(0xFFF44336)),
          const SizedBox(height: 24),
          Text(
            _result,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar(String label, double probability, Color color) {
    final percentage = (probability * 100).toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: probability,
            minHeight: 24,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHandResult({
    required String playerName,
    required String handDescription,
    required Color color,
    required bool isWinner,
    required List<String> cards,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWinner ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? color : Colors.white30,
          width: isWinner ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWinner ? Icons.star : Icons.person,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                playerName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            handDescription,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (cards.isNotEmpty) ...[  
            const SizedBox(height: 16),
            Text(
              'Best 5-Card Hand',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cards.map((card) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1929),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _convertToExcelFormat(card),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
