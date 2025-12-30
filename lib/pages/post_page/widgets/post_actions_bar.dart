
import 'package:flutter/material.dart';

import '../../../util/HelperUtil.dart';

class PostActionsBar extends StatelessWidget {
  final String userRole;
  final List<String> categories;
  final List<String> selectedCategories;

  final TextEditingController searchController;
  final VoidCallback onFilterTapped;
  final VoidCallback onUploadTapped;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchClear;

  final PostMediaFilter mediaFilter;
  final ValueChanged<PostMediaFilter> onMediaFilterChanged;

  const PostActionsBar({
    super.key,
    required this.userRole,
    required this.categories,
    required this.selectedCategories,
    required this.searchController,
    required this.onFilterTapped,
    required this.onUploadTapped,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchClear,
    required this.mediaFilter,
    required this.onMediaFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [

          // Zeile mit Filter- & Upload-Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.05,
                  bottom: 15,
                ),
                child: GestureDetector(
                  onTap: onFilterTapped,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[700],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 25,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Kategorien",
                          softWrap: true,
                          style: TextStyle(
                            height: 0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: 15,
                  right: MediaQuery.of(context).size.width * 0.05,
                ),
                child: GestureDetector(
                  onTap: onUploadTapped,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.orange,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.upload,
                          size: 25,
                          color: Colors.black,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Hochladen",
                          softWrap: true,
                          style: TextStyle(
                            height: 0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SegmentedButton<PostMediaFilter>(
                    segments: const [
                      ButtonSegment(
                        value: PostMediaFilter.all,
                        label: Text("Alle"),
                        icon: Icon(Icons.grid_view, size: 18),
                      ),
                      ButtonSegment(
                        value: PostMediaFilter.videos,
                        label: Text("Videos"),
                        icon: Icon(Icons.video_collection, size: 18),
                      ),
                      ButtonSegment(
                        value: PostMediaFilter.images,
                        label: Text("Bilder"),
                        icon: Icon(Icons.image, size: 18),
                      ),
                    ],
                    selected: {mediaFilter},
                    onSelectionChanged: (set) {
                      if (set.isEmpty) return;
                      onMediaFilterChanged(set.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.orange;
                        }
                        return Colors.grey[800];
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return Colors.white;
                      }),
                      side: WidgetStateProperty.all(
                        const BorderSide(color: Colors.white24, width: 1),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),


          // Suchfeld
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 40,
              width: MediaQuery.of(context).size.width * 0.9,
              child: TextField(
                controller: searchController,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  decorationThickness: 0.0,
                ),
                textAlignVertical: TextAlignVertical.center,
                maxLength: 25,
                textInputAction: TextInputAction.search,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: "",
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  prefixIcon: GestureDetector(
                    onTap: () {
                      if (searchController.text.trim().isNotEmpty) {
                        onSearchSubmitted(searchController.text);
                      }
                    },
                    child: const Icon(
                      Icons.search_outlined,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: onSearchClear,
                    child: const Icon(
                      Icons.close_outlined,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  hintText: "Suche...",
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
