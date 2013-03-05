var onLoad = function(){
	var loginFlowershop = $( "#loginFlowershop" );
	var createFlowershop = $( "#createFlowershop" );

	$("#swapLoginButton").on("click", function(event){
		loginFlowershop.show();
		createFlowershop.hide();
	});

	$("#swapCreateButton").on("click", function(event){
		loginFlowershop.hide();
		createFlowershop.show();
	});

}

$(document).ready(onLoad)