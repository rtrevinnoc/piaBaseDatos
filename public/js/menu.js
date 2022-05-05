$(document).ready(function(){
	const nombre = $('#empleadoNombre');
	const sueldo = $('#empleadoSueldo');
	const entrada = $('#empleadoEntrada');
	const salida = $('#empleadoSalida');
	const sede = $('#empleadoSede');
	const edificio = $('#empleadoEdificio');
	const piso = $('#empleadoPiso');
	const cuarto = $('#empleadoCuarto');
	const dir = $('#empleadoDir');
	const gerente = $('#empleadoGerente');

	nombre.on("input", function() {
		console.log(this.value)
		$.getJSON('/verEmpleado', {
			empleado: this.value
		}, function(data) {
			console.log(data)

			nombre.value = data['nombre']
			sueldo.value = data['sueldo']
			entrada.value = data['entrada']
			salida.value = data['salida']
			sede.value = data['sede']
			edificio.value = data['edificio']
			piso.value = data['piso']
			cuarto.value = data['cuarto']
			dir.value = data['dir']
			gerente.checked = data['gerente']
		});
	});
})
