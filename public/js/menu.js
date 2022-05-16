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
			sueldo.val(currency(data['sueldo']))
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

	const reservaciones = $('#reservacionesTabla');

	$.getJSON('/verReservaciones', function(data) {
		data.forEach(res => {
			reservaciones.append( "<tr><td>" + res['sede'] + "</td><td>" + res['edificio'] + "</td><td>" + res['piso'] + "</td><td>" + res['habitacion'] + "</td><td>" + res['categoria'] + "</td><td>" + res['llegada'] + "</td><td>" + res['salida'] + "</td><td>" + res['pagada'] + "</td></tr>" );
		});
	});

	const adminReservaciones = $('#adminReservacionesTabla');

	$.getJSON('/adminReservaciones', function(data) {
		console.log(data)

		data.forEach(res => {
			adminReservaciones.append( "<tr><td>" + res['sede'] + "</td><td>" + res['edificio'] + "</td><td>" + res['piso'] + "</td><td>" + res['habitacion'] + "</td><td>" + res['categoria'] + "</td><td>" + res['llegada'] + "</td><td>" + res['salida'] + "</td><td>" + res['pagada'] + "</td></tr>" );
		});
	});
})
