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

class _PokerHomePageState extends State<PokerHomePage> {
  // Use localhost for development, GKE IP for production
  final String apiUrl = kDebugMode 
      ? 'http://localhost:8080'
      : 'http://136.113.179.68';
  
  final TextEditingController _holeCard1Controller = TextEditingController();
  final TextEditingController _holeCard2Controller = TextEditingController();
  final TextEditingController _flop1Controller = TextEditingController();
  final TextEditingController _flop2Controller = TextEditingController();
  final TextEditingController _flop3Controller = TextEditingController();
  final TextEditingController _turnController = TextEditingController();
  final TextEditingController _riverController = TextEditingController();
  final TextEditingController _numPlayersController = TextEditingController(text: '6');
  final TextEditingController _simulationsController = TextEditingController(text: '1000');
  
  String _result = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to trigger rebuild when cards change
    _holeCard1Controller.addListener(() => setState(() {}));
    _holeCard2Controller.addListener(() => setState(() {}));
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

  Future<void> evaluateHand() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'holeCards': [_holeCard1Controller.text, _holeCard2Controller.text],
          'communityCards': [
            _flop1Controller.text,
            _flop2Controller.text,
            _flop3Controller.text,
            _turnController.text,
            _riverController.text,
          ].where((c) => c.isNotEmpty).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _result = 'Hand: ${data['handRank']}\n'
                'Description: ${data['description']}\n'
                'Best 5 cards: ${(data['cards'] as List).join(', ')}';
          });
        } else {
          setState(() {
            _result = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _result = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> calculateProbability() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/probability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'holeCards': [_holeCard1Controller.text, _holeCard2Controller.text],
          'communityCards': [
            _flop1Controller.text,
            _flop2Controller.text,
            _flop3Controller.text,
            _turnController.text,
            _riverController.text,
          ].where((c) => c.isNotEmpty).toList(),
          'numPlayers': int.parse(_numPlayersController.text),
          'simulations': int.parse(_simulationsController.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final winProb = (data['winProbability'] * 100).toStringAsFixed(2);
          final tieProb = (data['tieProbability'] * 100).toStringAsFixed(2);
          final lossProb = (data['lossProbability'] * 100).toStringAsFixed(2);
          setState(() {
            _result = 'Win Probability: $winProb%\n'
                'Tie Probability: $tieProb%\n'
                'Loss Probability: $lossProb%\n'
                'Simulations: ${data['simulations']}';
          });
        } else {
          setState(() {
            _result = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _result = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
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
                const SizedBox(height: 32),
                
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
          // Hole cards section
          _buildHoleCardsSection(),
          
          const SizedBox(height: 32),
          const Divider(color: Color(0xFF00E5FF), thickness: 2),
          const SizedBox(height: 32),
          
          // Community cards section
          _buildCommunityCardsSection(),
          
          const SizedBox(height: 32),
          const Divider(color: Color(0xFF00E5FF), thickness: 2),
          const SizedBox(height: 32),
          
          // Settings section
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildHoleCardsSection() {
    final card1 = parseCard(_holeCard1Controller.text);
    final card2 = parseCard(_holeCard2Controller.text);

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF00E5FF), size: 24),
            const SizedBox(width: 12),
            Text(
              'YOUR HOLE CARDS',
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
                controller: _holeCard1Controller,
                label: 'CARD 1',
                hint: 'HA',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardInput(
                controller: _holeCard2Controller,
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

  Widget _buildSettingsSection() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFF00E5FF), size: 24),
            const SizedBox(width: 12),
            Text(
              'GAME SETTINGS',
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
                hint: '6',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCardInput(
                controller: _simulationsController,
                label: 'SIMULATIONS',
                hint: '1000',
                keyboardType: TextInputType.number,
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
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : evaluateHand,
              icon: const Icon(Icons.casino, size: 24),
              label: const Text('EVALUATE HAND'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0A1929),
                minimumSize: const Size(200, 56),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _loading ? null : calculateProbability,
              icon: const Icon(Icons.calculate, size: 24),
              label: const Text('WIN PROBABILITY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 56),
              ),
            ),
          ],
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
    final lines = _result.split('\n');
    final isEvaluation = _result.contains('Hand:');
    
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF),
                      const Color(0xFF00BCD4),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEvaluation ? Icons.emoji_events : Icons.show_chart,
                  color: const Color(0xFF0A1929),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                isEvaluation ? 'HAND RESULT' : 'WIN PROBABILITY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00E5FF),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildResultLine(line),
          )),
        ],
      ),
    );
  }

  Widget _buildResultLine(String line) {
    final parts = line.split(':');
    if (parts.length == 2) {
      final label = parts[0].trim();
      final value = parts[1].trim();
      final isPercentage = value.contains('%');
      
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isPercentage ? 20 : 18,
                color: isPercentage ? const Color(0xFF00E5FF) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      line,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
