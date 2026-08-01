import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key, required this.controller}); final AppController controller;
  @override Widget build(BuildContext context) { final m=controller.mapping; return KemsPage(children:[
    const SectionTitle('KEMS intelligence'),
    KemsCard(glow: KemsTheme.purple,child:Row(children:[const Icon(Icons.science_outlined,color:KemsTheme.purple,size:36),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Current phase',style:TextStyle(color:Colors.white54)),Text(controller.entity(m.phase)?.state ?? 'Observe',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800)),Text(controller.entity(m.status)?.state ?? 'Learning from Home Assistant',style:const TextStyle(color:Colors.white60))]))])),
    const SectionTitle('System readiness'),
    _row('Learning confidence',displayEntity(controller,m.learningConfidence),Icons.psychology,KemsTheme.purple),
    const SizedBox(height:10),_row('Data quality',displayEntity(controller,m.dataQuality),Icons.data_usage,KemsTheme.cyan),
    const SizedBox(height:10),_row('Simulation',controller.isOn(m.simulationReady)?'Ready':'Collecting data',Icons.model_training,KemsTheme.green),
    const SizedBox(height:10),_row('ROI prediction',controller.isOn(m.roiReady)?'Ready':'Not ready',Icons.savings_outlined,KemsTheme.amber),
    const SectionTitle('Current advice'),
    KemsCard(child:Text(controller.entity(m.advice)?.state ?? 'KEMS is observing your energy use.',style:const TextStyle(fontSize:16,height:1.5))),
    const SectionTitle('Next planned milestone'),
    KemsCard(child:Row(children:[const Icon(Icons.flag_outlined,color:KemsTheme.green),const SizedBox(width:12),Expanded(child:Text(controller.isOn(m.learningReady)?'Learning complete — ready for simulation':'Continue collecting clean history until learning readiness is reached'))])),
  ]); }
  Widget _row(String l,String v,IconData i,Color c)=>KemsCard(child:Row(children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:c.withValues(alpha:.12),borderRadius:BorderRadius.circular(12)),child:Icon(i,color:c)),const SizedBox(width:12),Expanded(child:Text(l,style:const TextStyle(fontWeight:FontWeight.w700))),Text(v,style:TextStyle(color:c,fontWeight:FontWeight.w800))]));
}
