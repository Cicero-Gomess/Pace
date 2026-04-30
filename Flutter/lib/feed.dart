import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
 State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Map<String, dynamic>> posts = [
    {
      "nome": "Eduardo",
      "usuario": "@edu",
      "texto": "Primeiro post no Pace 🚀",
      "imagem": "",
      "likes": 5,
      "liked": false,
      "comentarios": 2
    },
    {
      "nome": "Maria",
      "usuario": "@maria",
      "texto": "Estudando muito hoje 💪",
      "imagem": "",
      "likes": 10,
      "liked": true,
      "comentarios": 4
    }
  ];

  void toggleLike(int index) {
    setState(() {
      posts[index]["liked"] = !posts[index]["liked"];
      posts[index]["likes"] += posts[index]["liked"] ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ===== SIDEBAR =====
          Container(
            width: 90,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset("assets/logo.png", width: 40),

                const SizedBox(height: 40),

                sidebarItem(Icons.home, "Feed", true),
                sidebarItem(Icons.flag, "Metas", false),
                sidebarItem(Icons.explore, "Explorar", false),
                sidebarItem(Icons.add_box, "Postar", false),
                sidebarItem(Icons.notifications, "Notificações", false),

                const Divider(),

                sidebarItem(Icons.settings, "Config", false),

                const Spacer(),

                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      AssetImage("assets/user.png"),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ===== CONTEÚDO =====
          Expanded(
            child: Container(
              color: const Color(0xFFF4F7FB),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ===== HERO =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Comunidade em movimento",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Seu feed no Pace",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Acompanhe a comunidade evoluindo.",
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),

                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        label: const Text("Criar post"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3059AA),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===== LISTA DE POSTS =====
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOPO
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundImage:
                                        AssetImage("assets/user.png"),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(post["nome"]),
                                      Text(
                                        post["usuario"],
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12),
                                      )
                                    ],
                                  )
                                ],
                              ),

                              const SizedBox(height: 10),

                              // TEXTO
                              Text(post["texto"]),

                              const SizedBox(height: 10),

                              // AÇÕES
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        toggleLike(index),
                                    icon: Icon(
                                      Icons.favorite,
                                      color: post["liked"]
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    label: Text(
                                        "${post["likes"]}"),
                                  ),

                                  const SizedBox(width: 10),

                                  Row(
                                    children: [
                                      const Icon(Icons.comment,
                                          size: 18),
                                      const SizedBox(width: 5),
                                      Text(
                                          "${post["comentarios"]}")
                                    ],
                                  )
                                ],
                              ),

                              const SizedBox(height: 10),

                              // INPUT COMENTÁRIO
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText:
                                            "Compartilhe algo...",
                                        filled: true,
                                        fillColor:
                                            Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  30),
                                          borderSide:
                                              BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    backgroundColor:
                                        const Color(0xFF3059AA),
                                    child: const Icon(Icons.send,
                                        color: Colors.white),
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget sidebarItem(IconData icon, String text, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Icon(
        icon,
        color: active ? Colors.blue : Colors.grey,
      ),
    );
  }
}