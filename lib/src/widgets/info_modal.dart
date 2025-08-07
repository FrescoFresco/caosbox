import 'package:flutter/material.dart';
import '../models/models.dart' as models;

void showInfoModal(BuildContext ctx, models.Item it, models.AppState st){
  showModalBottomSheet(context: ctx, builder: (_)=>Padding(
    padding:const EdgeInsets.all(24),
    child:Column(mainAxisSize:MainAxisSize.min, children:[
      Text(it.text,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      Text('ID: ${it.id}  •  Estado: ${it.status.name}'),
      const SizedBox(height:24),
      ElevatedButton(onPressed:()=>Navigator.pop(ctx), child:const Text('Cerrar'))
    ]),
  ));
}
