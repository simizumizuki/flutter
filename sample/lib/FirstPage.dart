import 'package:flutter/material.dart';
import 'SecondPage.dart';

class FirstPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("ページ(1)")
      ),
      body : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: Text("2ページに遷移する"),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SecondPage()
                ));
              },
            ),
            TextButton(
              child: Text("ホームに戻る"),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
          ],
        ),
      )
    );
  }
}