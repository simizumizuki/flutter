import 'package:flutter/material.dart';
import 'ThirdPage.dart';

class SecondPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("ページ(2)")
      ),
      body : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: Text("3ページに遷移する"),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ThirdPage()
                ));
              },
            ),
            TextButton(
              child: Text("1ページに戻る"),
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