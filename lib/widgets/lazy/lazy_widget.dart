import 'package:flutter/material.dart';
import 'package:kol_miner/constants.dart';
import 'package:kol_miner/kol_network.dart';
import 'package:kol_miner/lazy_requests.dart';
import 'package:kol_miner/widgets/platformui.dart';

/// This widget is for use by lazy people who are a burden to humanity
class LazyUselessPersonWidget extends StatefulWidget {
  final KolNetwork network;

  LazyUselessPersonWidget(
    this.network, {
    Key key,
  }) : super(key: key);
  LazyPersonState _state;
  @override
  State<StatefulWidget> createState() {
    // are we allowed to cache States? I'd think so
    _state = LazyPersonState();
    return _state;
  }

  /// update the data from api.php
  updateData() {
    _state.updatePlayerData();
  }
}

class LazyPersonState extends State<LazyUselessPersonWidget> {
  String _mp = "";
  LazyRequest lazyRequest;

  initState() {
    super.initState();
    lazyRequest = LazyRequest(widget.network);
    updatePlayerData();
  }

  @override
  Widget build(BuildContext context) {
    if (DEBUG) {
      return new Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Column(
          children: <Widget>[
            buildInfoBox(),
            getButtonForAction('Resolve to spend MP', _onResolveClicked),
            // cast resol
            getButtonForAction('Healz', _onHealClicked),
            // Heals from nunnery
            getButtonForAction('Eat', _onEatClicked),
            // Eat sleazy hi mein
            getButtonForAction('Drink', _onDrinkClicked), // Eat sleazy hi mein
          ],
        ),
      );
    }
    // not allowed to show lazy widget, so show empty widget
    return new Container();
  }

  Widget getButtonForAction(String label, VoidCallback onPressed) {
    return Padding(
        padding: EdgeInsets.all(2.0),
        child: getPlatformButton(
          context,
          onPressed: onPressed,
          child: new Text(
            label,
          ),
          color: Theme.of(context).primaryColor,
        ));
  }

  Widget buildInfoBox() {
    if (lazyRequest == null || _mp.isEmpty) {
      return Text("RUNNING IN DEBUG MODE");
    }
    return Text("RUNNING IN DEBUG MODE\nHP: ${lazyRequest.currentHp} "
        "MP: $_mp "
        "advs: ${lazyRequest.advs} "
        "ode: ${lazyRequest.odeTurns} "
        "milk: ${lazyRequest.currentMilkTurns}");
  }

  updatePlayerData() {
    lazyRequest
        .getPlayerData()
        .then((_) => setState(() => _mp = lazyRequest.currentMp));
  }

  _onDrinkClicked() {
    lazyRequest.requestPerfectDrink().then((code) => updatePlayerData());
  }

  _onEatClicked() {
    lazyRequest.requestEatSleazyHimein().then((code) => updatePlayerData());
  }

  _onResolveClicked() {
    lazyRequest.requestResolutionSummon().then((code) => updatePlayerData());
  }

  _onHealClicked() {
    lazyRequest.requestNunHealing().then((code) => updatePlayerData());
  }
}
