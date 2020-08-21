import 'dart:convert';
import 'dart:io';
import 'package:date_format/date_format.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'aboutPage.dart';
import 'editPage.dart';

void main() {

  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List<Map<String, dynamic>> _toDoList = [];

  Map<String, dynamic> _lastRemove;
  int _lastRemovenPos;

  static DateTime _data = new DateTime.now();//inicializa data com a data de hj
  static var dataAtual = '${formatDate(_data, [dd, '/', mm, '/', yyyy])}';
  var _dataAtual = dataAtual.toString();

  @override
  void initState() {
    super.initState();
    _readData().then((dados) {
      setState(() {
        _toDoList = List<Map<String, dynamic>>.from(json.decode(dados));
      });
    });
  }

  void _addToDo() {
    setState(() {
      //setState atualiza o estado da tela sempre que colocar um novo elmento na lista
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;//recebe o texto escrito
      _toDoController.text = "";
      newToDo["ok"] = false; //o novo elemento da lista vem desmarcado
      _toDoList.add(newToDo);
      newToDo["date"] = _dataAtual;
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(milliseconds: 300));
    setState(() {
      _toDoList.sort((a, b) {
        //a e b são mapas da lista
        if (a["ok"] && !b["ok"])
          return 1; //ouseja, diz que "a>b"
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0; // se os elementos da lista estão no mesmo estado de check
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To do List"),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "New Task",
                        labelStyle: TextStyle(color: Colors.blueGrey)),
                    maxLines: null,
                  ),
                ),
                RaisedButton(
                    color: Colors.blueGrey,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed: _addToDo)
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          ))
        ],
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Drawer Header',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('About us'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget slideRightBackground() {
    return Container(
      color: Colors.green,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              Icons.edit,
              color: Colors.white,
            ),
            Text(
              " Edit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            Text(
              " Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }


  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: slideRightBackground(),
      secondaryBackground: slideLeftBackground(),

      //direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        activeColor: Colors.blueGrey,
        title: Text(_toDoList[index]["title"]),
        subtitle: Text(_toDoList[index]["date"]),//_toDoList[index]["date"]
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
            backgroundColor: _toDoList[index]["ok"] ? Colors.green : Colors.red,
            child: Icon(
              _toDoList[index]["ok"] ? Icons.check : Icons.error,
              color: Colors.white,
            )),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          /// edit item
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      EditPage(_toDoList[index], this.setState)));
          return false;
        } else if (direction == DismissDirection.endToStart) {
          /// delete
          return true;
        }
        return false;
      },

      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          //se for uma deleção
          setState(() {
            //atualiza pagina ao apagar um item
            _lastRemove = Map.from(_toDoList[index]);
            _lastRemovenPos = index;
            _toDoList.removeAt(index);

            _saveData(); //salvar lista com o item removido
            final snack = SnackBar(
              content: Text("Task \"${_lastRemove["title"]}\" removed"),
              action: SnackBarAction(
                  label: "Undo",
                  onPressed: () {
                    setState(() {
                      _toDoList.insert(_lastRemovenPos, _lastRemove);
                      _saveData();
                    });
                  }),
              duration: Duration(seconds: 3),
            );
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snack);
          });
        }
        /*
        else if(direction ==DismissDirection.startToEnd){//editar
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => EditPage()));
        }  */
      },
    );
    //widget que permite apagar passando pra esquerda
  }

  Future<File> _getFile() async {
    //usa o async pq tem um await dentro
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/dados.json");
  }

  Future<File> _saveData() async {
    String dados = json.encode(
        _toDoList); //pega os dados da lista, passa pra json e coloca em data
    final file =
        await _getFile(); //recebe o arquivo quando ele vier pela get file
    return file
        .writeAsString(dados); //escreve o dado como texto dentro do arquivo
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile(); //recebe arquivo do getfile
      return file.readAsString(); //tenta ler como string
    } catch (e) {
      //se der erro no try, vem pro catch
      return null;
    }
  }
}
