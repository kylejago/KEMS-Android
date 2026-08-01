import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';

class SetupScreen extends StatefulWidget { const SetupScreen({super.key,required this.controller}); final AppController controller; @override State<SetupScreen> createState()=>_SetupScreenState(); }
class _SetupScreenState extends State<SetupScreen>{
 final url=TextEditingController(text:'http://homeassistant.local:8123/'); final token=TextEditingController(); bool hidden=true;
 @override void dispose(){url.dispose();token.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:KemsTheme.surface,borderRadius:BorderRadius.circular(26),border:Border.all(color:const Color(0xFF1C2D34))),child:Column(children:[
   Image.asset('assets/branding/kems_mark.png',width:112,height:112),
   const Text('Connect KEMS',style:TextStyle(fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(height:8),
   const Text('Link KEMS Companion to Home Assistant. Your access token is encrypted on this device.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white60,height:1.4)),const SizedBox(height:24),
   TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Home Assistant URL',hintText:'http://homeassistant.local:8123/',prefixIcon:Icon(Icons.home_outlined))),const SizedBox(height:14),
   TextField(controller:token,obscureText:hidden,decoration:InputDecoration(labelText:'Long-Lived Access Token',prefixIcon:const Icon(Icons.key_outlined),suffixIcon:IconButton(onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility_outlined:Icons.visibility_off_outlined)))),
   if(widget.controller.error!=null)...[const SizedBox(height:14),Container(width:double.infinity,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:KemsTheme.red.withValues(alpha:.10),borderRadius:BorderRadius.circular(12)),child:Text(widget.controller.error!,style:const TextStyle(color:KemsTheme.red)))],
   const SizedBox(height:22),SizedBox(width:double.infinity,height:54,child:FilledButton.icon(onPressed:widget.controller.loading?null:()async{final ok=await widget.controller.saveConfiguration(url.text.trim(),token.text.trim());if(!ok&&mounted)setState((){});},icon:widget.controller.loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.link),label:const Text('Connect to Home Assistant',style:TextStyle(fontWeight:FontWeight.w800)))),
   const SizedBox(height:12),const Text('Home Assistant remains the secure source of truth.',style:TextStyle(color:Colors.white38,fontSize:11)),
 ])))))));
}
