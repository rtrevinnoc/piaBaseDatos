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
		$.getJSON('/verEmpleado', {
			empleado: this.value
		}, function(data) {
			console.log(data)

			nombre.val(data['nombre'])
			sueldo.val(data['sueldo'])
			entrada.val(data['entrada'])
			salida.val(data['salida'])
			sede.val(data['sede'])
			edificio.val(data['edificio'])
			piso.val(data['piso'])
			cuarto.val(data['cuarto'])
			dir.val(data['dir'])
			gerente.prop('checked', data['gerente'])
		});
	});
})
