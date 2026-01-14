import 'package:flutter/material.dart';

class ThirdPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("ページ(3)")
      ),
      body : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: Text("2ページに戻る"),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("ホームに戻る"),
              onPressed: (){
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            )
          ],
          
        ),
      )
    );
  }
}