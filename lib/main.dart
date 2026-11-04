import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = TextEditingController();

  List<Map<String, dynamic>> songs = [];

  bool loading = false;
  String errorMessage = '';

  // MENCARI LAGU DARI API ITUNES

  Future<void> cariLagu() async {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      loading = true;
      errorMessage = '';
      songs = [];
    });

    final url = Uri.https(
      'itunes.apple.com',
      '/search',
      {
        'term': controller.text.trim(),
        'limit': '10',
        'entity': 'song',
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            songs = List<Map<String, dynamic>>.from(
              data['results'] ?? [],
            );
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Gagal mengambil data lagu.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Periksa koneksi internet kamu.';
        });
      }

      debugPrint('Search Error: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Music Player',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // SEARCH BAR

            TextField(
              controller: controller,
              onSubmitted: (value) => cariLagu(),

              style: const TextStyle(
                color: Colors.white,
              ),

              decoration: InputDecoration(
                hintText: 'Cari judul lagu atau artis...',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),

                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                ),

                filled: true,
                fillColor: const Color(0xFF282828),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SEARCH BUTTON

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: loading ? null : cariLagu,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text('Cari Lagu'),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Hasil Pencarian',

              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // DAFTAR LAGU

            Expanded(
              child: loading

                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DB954),
                ),
              )

                  : errorMessage.isNotEmpty

                  ? Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              )

                  : songs.isEmpty

                  ? const Center(
                child: Text(
                  'Cari lagu favorit kamu!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              )

                  : ListView.builder(
                itemCount: songs.length,

                itemBuilder: (context, index) {
                  final song = songs[index];

                  return ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 5,
                    ),

                    // COVER LAGU

                    leading: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(8),

                      child: Image.network(
                        song['artworkUrl100'] ?? '',
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,

                        errorBuilder:
                            (context, error, stack) {
                          return Container(
                            width: 55,
                            height: 55,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),

                    // JUDUL LAGU

                    title: Text(
                      song['trackName'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // NAMA PENYANYI

                    subtitle: Text(
                      song['artistName'] ?? '-',

                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    trailing: const Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFF1DB954),
                      size: 30,
                    ),

                    // MEMBUKA HALAMAN PLAYER

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              PlayerPage(song: song),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ================= HALAMAN PEMUTAR MUSIK =================

class PlayerPage extends StatefulWidget {
  final Map<String, dynamic> song;

  const PlayerPage({
    super.key,
    required this.song,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {

  final AudioPlayer player = AudioPlayer();

  bool loading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    putarLagu();
  }

  // MEMUTAR LAGU

  Future<void> putarLagu() async {
    final url = widget.song['previewUrl'];

    if (url == null || url.toString().isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Preview lagu tidak tersedia.';
        });
      }

      return;
    }

    try {
      await player.play(
        UrlSource(url.toString()),
      );

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Audio Error: $e');

      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Gagal memutar lagu. Periksa koneksi internet.';
        });
      }
    }
  }

  // PLAY DAN PAUSE

  Future<void> playPause() async {
    if (player.state == PlayerState.playing) {
      await player.pause();
    } else if (player.state == PlayerState.completed) {
      await player.seek(Duration.zero);
      await player.resume();
    } else {
      await player.resume();
    }
  }

  // FORMAT DURASI LAGU

  String formatWaktu(Duration duration) {
    String menit = duration.inMinutes
        .toString()
        .padLeft(2, '0');

    String detik = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$menit:$detik';
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final song = widget.song;

    // MENGAMBIL INFORMASI LAGU

    final judul = song['trackName'] ?? '-';
    final penyanyi = song['artistName'] ?? '-';

    final artwork = song['artworkUrl100'] != null
        ? song['artworkUrl100']
        .toString()
        .replaceAll('100x100', '600x600')
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Now Playing'),
        centerTitle: true,
      ),

      // AGAR HALAMAN BISA DI-SCROLL

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [

              // COVER ALBUM

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),

                  child: Image.network(
                    artwork,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stack) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[800],

                        child: const Icon(
                          Icons.music_note,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // JUDUL LAGU

              Text(
                judul,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // NAMA PENYANYI

              Text(
                penyanyi,

                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 30),

              // SLIDER DAN DURASI MUSIK

              StreamBuilder<Duration>(
                stream: player.onDurationChanged,
                initialData: Duration.zero,

                builder: (context, durationSnapshot) {

                  final duration =
                      durationSnapshot.data ?? Duration.zero;

                  return StreamBuilder<Duration>(
                    stream: player.onPositionChanged,
                    initialData: Duration.zero,

                    builder: (context, positionSnapshot) {

                      final position =
                          positionSnapshot.data ?? Duration.zero;

                      final maxDuration =
                      duration.inMilliseconds.toDouble();

                      final currentPosition = position
                          .inMilliseconds
                          .toDouble()
                          .clamp(
                        0.0,
                        maxDuration > 0 ? maxDuration : 1.0,
                      );

                      return Column(
                        children: [

                          Slider(
                            value: currentPosition,

                            max: maxDuration > 0
                                ? maxDuration
                                : 1,

                            activeColor: const Color(0xFF1DB954),
                            inactiveColor: Colors.grey[700],

                            onChanged: maxDuration > 0
                                ? (value) {
                              player.seek(
                                Duration(
                                  milliseconds: value.toInt(),
                                ),
                              );
                            }
                                : null,
                          ),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                            children: [

                              Text(
                                formatWaktu(position),

                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),

                              Text(
                                formatWaktu(duration),

                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // TOMBOL PEMUTAR MUSIK

              if (loading)

                const CircularProgressIndicator(
                  color: Color(0xFF1DB954),
                )

              else if (errorMessage.isNotEmpty)

                Text(
                  errorMessage,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                )

              else

                StreamBuilder<PlayerState>(
                  stream: player.onPlayerStateChanged,
                  initialData: player.state,

                  builder: (context, snapshot) {

                    final isPlaying =
                        snapshot.data == PlayerState.playing;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        // SHUFFLE

                        const Icon(
                          Icons.shuffle,
                          color: Colors.grey,
                          size: 25,
                        ),

                        const SizedBox(width: 20),

                        // REPLAY

                        IconButton(
                          onPressed: () async {
                            await player.seek(Duration.zero);
                            await player.resume();
                          },

                          icon: const Icon(
                            Icons.replay,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 15),

                        // PLAY / PAUSE

                        IconButton(
                          onPressed: playPause,

                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,

                            color: const Color(0xFF1DB954),
                            size: 75,
                          ),
                        ),

                        const SizedBox(width: 15),

                        // NEXT

                        IconButton(
                          onPressed: () async {
                            await player.seek(
                              Duration.zero,
                            );

                            await player.pause();
                          },

                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 20),

                        // REPEAT

                        const Icon(
                          Icons.repeat,
                          color: Colors.grey,
                          size: 25,
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 35),

              // INFORMASI LAGU

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Informasi Lagu',

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Album: ${song['collectionName'] ?? '-'}',

                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Genre: ${song['primaryGenreName'] ?? '-'}',

                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Tanggal Rilis: ${song['releaseDate'] != null ? song['releaseDate'].toString().substring(0, 10) : '-'}',

                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Artis: $penyanyi',

                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
