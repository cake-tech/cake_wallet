import 'package:cake_wallet/live_demo/vm/live_demo_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class LiveDemoConfigPage extends StatefulWidget {
  const LiveDemoConfigPage({super.key, required this.bloc});

  final LiveDemoBloc bloc;

  @override
  State<LiveDemoConfigPage> createState() => _LiveDemoConfigPageState();
}

class _LiveDemoConfigPageState extends State<LiveDemoConfigPage> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
  create: (context) => widget.bloc,
  child: BlocConsumer<LiveDemoBloc, LiveDemoState>(
    listener: (context, state) {
      if(state is LiveDemoReady) {
        Navigator.of(context).popAndPushNamed(Routes.dashboard);
      }
    },
  builder: (context, state) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Text("checklist:\n-server started?\n-(iphone) local network perms given?\n-same network for server + client?"),
            TextField(decoration: InputDecoration(hintText: "host"),controller: _hostController,enabled: state is LiveDemoInitial,),
            TextField(decoration: InputDecoration(hintText: "port"),controller: _portController,enabled: state is LiveDemoInitial,),
            NewPrimaryButton(onPressed: (){context.read<LiveDemoBloc>().add(ConnectionRequested(host: _hostController.text, port: (int.tryParse(_portController.text)??-1)));}, text: "start", color: Theme.of(context).colorScheme.primary, textColor: Theme.of(context).colorScheme.onPrimary, disabled: state is! LiveDemoInitial,),
            if(state is LiveDemoConfiguring) Row(children: [CupertinoActivityIndicator(),Text(state.msg)],),
            if(state is LiveDemoError) ...[
            TextButton(onPressed: (){
    showMaterialModalBottomSheet(expand:true,context: context, builder: (context){
    return SingleChildScrollView(controller:ModalScrollController.of(context),child: SafeArea(child: Column(
    spacing:12,
    children: [
    Text(state.error),
    Text(state.stackTrace.toString()),
    ],
    )));


    });
    }, child: Text(state.error)),TextButton(onPressed: (){context.read<LiveDemoBloc>().add(PageReset());}, child: Text("try again"))]
          ]
        ),
      ),
    );
  },
),
);
  }
}
