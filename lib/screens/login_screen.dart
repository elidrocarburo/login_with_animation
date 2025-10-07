import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool passToggle = true;

  //cerebro de la lógica de las animaciones
  StateMachineController? controller;
  //SMI: State Machine Input
  SMIBool? isChecking; // activa el modo chismoso
  SMIBool? isHandsUp; // se tapa los ojos
  SMITrigger? trigSuccess; // se emociona
  SMITrigger? trigFail; // se pone triste (como yio)

  // 1) FocusNode 
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // 2) Listeners (oyentes/chismoso) escuchan todos los cambios que pasan
  @override
  void initState() {
    super.initState();
    emailFocus.addListener((){
      if (emailFocus.hasFocus){
      isHandsUp?.change(false); //Manos abajo cuando escribes el e-mail
      }
    });
    passFocus.addListener((){
      //Manos arriba en password
      isHandsUp?.change(passFocus.hasFocus);
    });
    
  }

  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla del dispositivo (consulta el tamaño)
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/animated_login_character.riv',
                  stateMachines: ["Login Machine"],
                  //al iniciarse
                  onInit: (artboard){
                  controller = StateMachineController.fromArtboard(artboard, "Login Machine");
                    //verificar que inició bien
                    if(controller == null) return ;
                    artboard.addController(controller!);
                    isChecking = controller!.findSMI('isChecking');
                    isHandsUp = controller!.findSMI('isHandsUp');
                    trigSuccess = controller!.findSMI('trigSuccess');
                    trigFail = controller!.findSMI('trigFail');
                  },
                  )
                ),
                //Espacio entre el oso y el texto email
                const SizedBox(
                  height: 10,
                ),
                //Campo de texto del email
                TextField(
                  //asignas el focusNode al TextField
                  //llamar al listener de email
                  focusNode: emailFocus,
                  onChanged: (value) {
                    if (isHandsUp != null){
                      //corroborar que acá no se tapen los ojos al escribir el correo
                      isHandsUp!.change(false);
                    }
                    if (isChecking == null) return;
                    //activa el modo chismoso
                    isChecking!.change(true);
                  },
                  //qué esperas en ese campo de texto (para que aparezca el @ en móviles)
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    //labelText: "E-mail", para que el hinttext pase arriba del campo de texto
                    hintText: "E-mail",
                    prefixIcon: const Icon(Icons.mail),
                    border: OutlineInputBorder(
                      //esquinas redondeadas
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                //Campo de texto de contraseña
                TextField(
                  focusNode: passFocus,
                  onChanged: (value) {
                    if (isChecking != null){
                      //corroborar que acá no se tapen los ojos al escribir el correo
                      //isHandsUp!.change(true);
                    }
                    if (isChecking == null) return;
                    //activa el modo chismoso
                    isChecking!.change(false);
                  },
                  //ocultar la contraseña
                  obscureText: passToggle ? true : false,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    //widget de material que gestiona la interacción que tenemos, permitiendo cambiar de estado
                    //en este caso, cambiando el icono + si podemos o no ver la contraseña
                    suffixIcon: InkWell(
                      onTap: (){
                        if(passToggle == true){
                          passToggle = false;
                        }
                        else {
                          passToggle = true;
                        }
                        setState(() {
                          
                        });
                      },
                      child: passToggle
                      ? Icon(Icons.remove_red_eye)
                      : Icon(Icons.visibility_off)
                      ,
                    ),
                    border: OutlineInputBorder(
                      //esquinas redondeadas
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                //Texto de 'olvidé la contraseña'
                SizedBox(height:10),
                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot your password?',
                    //alinear a la derecha
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: TextDecoration.underline
                    ),
                  )
                ),
                //Botón login
                SizedBox(height: 10),
                //botón estilo Android
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  onPressed: (){},
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?"
                        ),
                        TextButton(
                          onPressed: (){}, 
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline
                            ),
                          ))
                      ],
                    ),
                  )
            ],
          ),
        )),
    );
  }
  // 4) liberación de recursos /limpieza de focos
  @override
  void dispose() {
    emailFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }
}