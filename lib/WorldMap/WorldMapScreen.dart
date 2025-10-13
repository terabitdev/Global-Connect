import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:provider/provider.dart';


import '../Provider/VisitedCountriesProvider.dart';


class WorldMapScreen extends StatefulWidget {
  final String? userId;

  const WorldMapScreen({Key? key, this.userId}) : super(key: key);
  @override
  _WorldMapScreenState createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = widget.userId;
      Provider.of<VisitedCountriesProvider>(context, listen: false)
          .initializeVisitedCountriesStream(userId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VisitedCountriesProvider>(
        builder: (context, provider, child) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        boundaryMargin: EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.92,
                          child: SimpleMap(
                            instructions: SMapWorld.instructions,
                            defaultColor: Colors.grey[300]!,
                            colors: provider.countryColorsMap,

                            callback: (id, name, tapdetails) {
                              provider.handleCountryTap(id, name);
                            },

                          ),
                        ),
                      ),
                    ),
                  ),


                ],
              );
            },
          );
        },
      ),
    );
  }
}
