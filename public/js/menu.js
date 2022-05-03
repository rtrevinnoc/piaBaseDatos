$(document).ready(function(){
	const nombre = $('#empleadoNombre');

	nombre.on("input", function() {
		console.log(this.value)
		$.getJSON('/verEmpleado', {
		    empleado: this.value
		}, function(data) {
		    console.log(data);
		});
	});
})
