extends Node

## Referência ao nó que será rotacionado (a carta do jogador)
@onready var objeto_alvo = get_node("Carta")

## Armazena a rotação alvo como um quaternion
var rotacao_quat := Quaternion()

## Velocidade de interpolação da rotação (quanto menor, mais suave)
var suavidade_rotacao := 0.06

## Controle para resetar a rotação suavemente
var reset_solicitado := false

## Captura eventos de entrada do usuário
func _input(evento):
	## Verifica se o evento é movimento do mouse E se o botão esquerdo está pressionado
	if evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var delta = evento.relative

		## Rotação horizontal no eixo Y (global)
		var rot_x := Quaternion(Vector3.UP, deg_to_rad(delta.x * 0.5))

		## Rotação vertical no eixo X (local da carta)
		## TODO: testar com basis.z para rotação alternativa
		var local_direita = objeto_alvo.transform.basis.x ## Já é normalizado se a escala for 1
		var rot_y := Quaternion(local_direita, deg_to_rad(delta.y * 0.5))

		## Nova ordem: Rotação vertical (local X) deve ser aplicada depois da rotação horizontal (global Y)
		## para evitar roll indesejado.
		rotacao_quat = rot_y * rot_x * rotacao_quat
		rotacao_quat = rotacao_quat.normalized()

		## Cancela reset se o usuário interagir
		reset_solicitado = false
		
	## Tecla R ativa reset suave
	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_R:
		reset_solicitado = true
		## CORREÇÃO: Zere a rotação acumulada para que o objeto não salte ao soltar o R.
		rotacao_quat = Quaternion.IDENTITY
		get_viewport().set_input_as_handled() ## Impedir que outros nós vejam o 'R'

## Atualiza a rotação suavemente a cada frame
@warning_ignore("unused_parameter")
func _process(delta):
	## Obtém rotação atual como quaternion
	var quat_atual = objeto_alvo.quaternion

	## Define alvo: rotação desejada ou identidade se reset for solicitado
	var alvo := Quaternion.IDENTITY if reset_solicitado else rotacao_quat

	## Interpola suavemente entre atual e alvo
	var quat_suave = quat_atual.slerp(alvo, suavidade_rotacao)

	## Aplica rotação suavizada diretamente
	objeto_alvo.quaternion = quat_suave
