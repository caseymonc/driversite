var onLoad = function(){
	var login = $( "#login" );
	var create = $( "#create" );

	$("#swapLoginButton").on("click", function(event){
		login.show();
		create.hide();
	});

	$("#swapCreateButton").on("click", function(event){
		login.hide();
		create.show();
	});

}

$(document).ready(onLoad)