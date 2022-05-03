$(document).ready(function(){
	const nombre = $('#empleadoNombre');

	nombre.on("input", function() {
		console.log(this.val())
		$.getJSON('/verEmpleado', {
		    empleado: this.val()
		}, function(data) {
		    console.log(data);
		});
	});
})
