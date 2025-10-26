import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
//3.1 importar librería de Timer
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool passToggle = true;
  bool isLoading = false; // Nueva variable para controlar el estado de carga

  //cerebro de la lógica de las animaciones
  StateMachineController? controller;
  //SMI: State Machine Input
  SMIBool? isChecking; // activa el modo chismoso
  SMIBool? isHandsUp; // se tapa los ojos
  SMITrigger? trigSuccess; // se emociona
  SMITrigger? trigFail; // se pone triste (como yio)
  
  //2.1 variable para recorrido de la mirada
  SMINumber? numLook;

  // 1.1) FocusNode 
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  //3.2 ) variable timer para detener la mirada al dejar de teclear
  Timer? _typingDebounce; 

  // 4.1 declarar la variable "controller": controlar qué es lo que el usuario escribió y poder hacer algo con ello
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 errores para pintar (mostrar) en la UI
  String? emailError;
  String? passError;

  // Nuevas variables para el checklist
  Map<String, bool> passwordRequirements = {
    'Mínimo 8 caracteres': false,
    'Al menos una mayúscula': false,
    'Al menos una minúscula': false,
    'Al menos un número': false,
    'Al menos un carácter especial': false,
  };

  bool showPasswordChecklist = false;

  //4.3 validadores (características de función: tipo de retorno / nombre / lo que se va a recibir)
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // Función para validar requisitos individuales de la contraseña
  void validatePasswordRequirements(String password) {
    setState(() {
      passwordRequirements['Mínimo 8 caracteres'] = password.length >= 8;
      passwordRequirements['Al menos una mayúscula'] = password.contains(RegExp(r'[A-Z]'));
      passwordRequirements['Al menos una minúscula'] = password.contains(RegExp(r'[a-z]'));
      passwordRequirements['Al menos un número'] = password.contains(RegExp(r'[0-9]'));
      passwordRequirements['Al menos un carácter especial'] = password.contains(RegExp(r'[^A-Za-z0-9]'));
      
      // Mostrar el checklist solo cuando el campo de contraseña tiene foco y hay texto
      showPasswordChecklist = passFocus.hasFocus && password.isNotEmpty;
    });
  }

  // Widget del checklist de contraseña
  Widget _buildPasswordChecklist() {
  if (!showPasswordChecklist) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.all(10), // ← Padding más pequeño
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requisitos:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12, // ← Texto más pequeño
          ),
        ),
        const SizedBox(height: 6),
        Wrap( // ← Usar Wrap en lugar de Column
          spacing: 8,
          runSpacing: 4,
          children: passwordRequirements.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min, // ← Ocupar solo espacio necesario
              children: [
                Icon(
                  entry.value ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: entry.value ? Colors.green : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getShortRequirement(entry.key),
                  style: TextStyle(
                    color: entry.value ? Colors.green : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}

String _getShortRequirement(String requirement) {
  final shortMap = {
    'Mínimo 8 caracteres': '8+ letras',
    'Al menos una mayúscula': 'Mayúscula',
    'Al menos una minúscula': 'Minúscula',
    'Al menos un número': 'Número',
    'Al menos un carácter especial': 'Especial',
  };
  return shortMap[requirement] ?? requirement;
}

  // Widget del checklist de email
  Widget _buildEmailChecklist() {
    if (!emailFocus.hasFocus || emailCtrl.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final email = emailCtrl.text.trim();
    final isValid = isValidEmail(email);
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Formato de email válido',
            style: TextStyle(
              color: isValid ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 4.4 darle acción al botón
  Future<void> _onLogin() async {
    if (isLoading) return; // Evitar múltiples clics
    
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    
    //recalcular errores
    final eError = isValidEmail(email) ? null : 'Email inválido';
    final pError = isValidPassword(pass) 
      ? null 
      :'La contraseña no cumple con todos los requisitos';
  
    //4.5 para que se muestre en la ui el mensaje de error (Avisar que hubo un cambio)
    setState(() {
      emailError = eError;
      passError = pError; 
    });

    //4.6 cerrar el teclado y bajar las manos al momento de enviar
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    isChecking?.change(false);
    isHandsUp?.change(false);
    numLook?.value = 50.0; //mirada neutral

    //Activar estado de carga
    setState(() {
      isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      
      //Verificar si hay errores de validación
      final hasValidationErrors = eError != null || pError != null;
      
      if (hasValidationErrors) {
        //Si hay errores de validación, mostrar animación de falla
        trigFail?.fire();
      } else {

        final success = true;
        
        if (success) {
          trigSuccess?.fire();
        } 
      }
    } catch (e) {
      trigFail?.fire();
      setState(() {
        emailError = 'Error de conexión';
      });
    } finally {
      //Desactivar estado de carga sin importar el resultado
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 2.1) Listeners (oyentes/chismoso) escuchan todos los cambios que pasan
  @override
  void initState() {
    super.initState();
    
    //Listener para cambios en el campo de contraseña
    passCtrl.addListener(() {
      validatePasswordRequirements(passCtrl.text);
    });

    emailFocus.addListener((){
      if (emailFocus.hasFocus){
        isHandsUp?.change(false); //Manos abajo cuando escribes el e-mail
        //2.2 mirada neutral al enfocar e-mail (aún no se ha escrito nada)
        numLook?.value = 50.0;
        isHandsUp?.change(false);
      } else {
        // Ocultar checklist cuando pierde el foco
        setState(() {
          showPasswordChecklist = false;
        });
      }
    });
    
    passFocus.addListener((){
      //Manos arriba en password
      isHandsUp?.change(passFocus.hasFocus);
      
      //Mostrar/ocultar checklist basado en el foco
      setState(() {
        showPasswordChecklist = passFocus.hasFocus && passCtrl.text.isNotEmpty;
      });
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
                    //2.3 enlazar variable con la animación
                    numLook = controller!.findSMI('numLook');
                    //clamp
                  },
                )
              ),
              //Espacio entre el oso y el texto email
              const SizedBox(height: 10),
              
              //Campo de texto del email
              TextField(
                //1.3asignas el focusNode al TextField
                //llamar al listener de email
                focusNode: emailFocus,
                //4.8 enlazar controller al TextField
                controller: emailCtrl,
                //2.4 implementando numLook
                onChanged: (value) {
                  //verificar que el usuario está escribiendo
                  isChecking!.change(false);
                  //ajuste de límites de 0 a 100 (definido por el creador de la animación)
                  //80 medida de calibración (depende del tamaño de la pantalla)
                  final look = (value.length / 80.0 * 100.0).clamp(
                    0.0, //limite inferior
                    100.0 //limite superior
                  ); //obtener la cantidad de caracteres puestos en el campo
                  numLook?.value = look;
                  //3.3 debounce: si vuelve a teclear, volver a fijar la mirada en el campo y reinicia el contador
                  _typingDebounce?.cancel(); //cancela cualquier timer existente
                  _typingDebounce = Timer(const Duration(milliseconds: 3000), (){
                    if (!mounted) {
                      return; //si la pantalla se cierra
                    }
                    //mirada neutra
                    isChecking?.change(false);
                  });

                  if (isChecking == null) return;
                  //activa el modo chismoso
                  isChecking!.change(true);
                },
                //qué esperas en ese campo de texto (para que aparezca el @ en móviles)
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  //labelText: "E-mail", para que el hinttext pase arriba del campo de texto
                  hintText: "E-mail",
                  //4.9 mostrar el texto del error
                  errorText: emailError,
                  prefixIcon: const Icon(Icons.mail),
                  border: OutlineInputBorder(
                    //esquinas redondeadas
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
              ),
              // Checklist de email
              _buildEmailChecklist(),
              
              const SizedBox(height: 10),

              //Campo de texto de contraseña
              TextField(
                focusNode: passFocus,
                //4.8 enlazar controller al TextField
                controller: passCtrl,
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
                obscureText: passToggle,
                decoration: InputDecoration(
                  errorText: passError,
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  //widget de material que gestiona la interacción que tenemos, permitiendo cambiar de estado
                  //en este caso, cambiando el icono + si podemos o no ver la contraseña
                  suffixIcon: InkWell(
                    onTap: (){
                      setState(() {
                        passToggle = !passToggle;
                      });
                    },
                    child: passToggle
                      ? const Icon(Icons.remove_red_eye)
                      : const Icon(Icons.visibility_off),
                  ),
                  border: OutlineInputBorder(
                    //esquinas redondeadas
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
              ),
              // Checklist de contraseña
              _buildPasswordChecklist(),
              
              //Texto de 'olvidé la contraseña'
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              //botón estilo Android
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                //4.10 llamar función de login
                onPressed: isLoading ? null : _onLogin,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: isLoading ? null : (){}, 
                      child: const Text(
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
        )
      ),
    );
  }

  // 4.1) liberación de recursos /limpieza de focos
  @override
  void dispose() {
    //4.11 limpieza de los controllers
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}