
var GroupID=0;
$(".MotesGroup").click(function(){
	GroupID = $(this).attr("data-groupID");
	alert(GroupID);
});

$("#bigImgCon").css("background-color","black");
$("body").css("background-color","#E9EDF5");

// when Group image clicked
$("#img1").click(function(){
	$("#bigImgCon").slideToggle("slow");
	$(".btnselector").toggleClass("disabled");

	// setting the position of motes on image
	setCoord(1,0.11);
	setCoord(2,0.44);
	setCoord(3,0.72);
});

// activates when button clicked
$(".btnselector").click(function(){
	if (!($(this).hasClass("disabled"))) {
		$("#modalHeadreText").text($(this).text()+":");

		// in case "Flash" clicked
		if ($(this).text()=="Flash" ){
			$(".modalBody").html("\
				<p>Please upload your file here to Flash on the selected mote(s)</p>\
				<form id='upload' method='post' action='upload.php' enctype='multipart/form-data'>\
		            <div id='drop'>\
		                Drop Here\
		                <a>Browse</a>\
		                <input type='file' name='upl' multiple />\
		            </div>\
		            <ul>\
		                <!-- The file uploads will be shown here -->\
		            </ul>\
		        </form>\
			");

			//$.post("php/insert.php" , {"ActivityID":4 , "GroupID":3 , "JobDate":"03.12.13" , "JobID":5 , "MoteID":1 , "UserID":3});

			
			
			// Insert job to the DB
			$("tr.SelectedMote").each(function(){
				var MoteID = $(this).attr("data-MoteID");
				var currentTime = new Date();
				var JsonToSend = {
					"DBTable":"job" ,
					"ActivityID":4 ,
					"GroupID":GroupID ,
					"JobDate":currentTime ,
					"JobID":5 ,
					"MoteID":MoteID ,
				"UserID":3};
				InsertToDB(JsonToSend);
				
			});


			// The uploader: Directly added from its website


			var ul = $('#upload ul');

		    $('#drop a').click(function(){
		        // Simulate a click on the file input button
		        // to show the file browser dialog
		        $(this).parent().find('input').click();
		    });

		    // Initialize the jQuery File Upload plugin
		    $('#upload').fileupload({

		        // This element will accept file drag/drop uploading
		        dropZone: $('#drop'),

		        // This function is called when a file is added to the queue;
		        // either via the browse button, or via drag/drop:
		        add: function (e, data) {

		            var tpl = $('<li class="working"><input type="text" value="0" data-width="48" data-height="48"'+
		                ' data-fgColor="#0788a5" data-readOnly="1" data-bgColor="#3e4043" /><p></p><span></span></li>');

		            // Append the file name and file size
		            tpl.find('p').text(data.files[0].name)
		                         .append('<i>' + formatFileSize(data.files[0].size) + '</i>');

		            // Add the HTML to the UL element
		            data.context = tpl.appendTo(ul);

		            // Initialize the knob plugin
		            tpl.find('input').knob();

		            // Listen for clicks on the cancel icon
		            tpl.find('span').click(function(){

		                if(tpl.hasClass('working')){
		                    jqXHR.abort();
		                }

		                tpl.fadeOut(function(){
		                    tpl.remove();
		                });

		            });

		            // Automatically upload the file once it is added to the queue
		            var jqXHR = data.submit();
		        },

		        progress: function(e, data){

		            // Calculate the completion percentage of the upload
		            var progress = parseInt(data.loaded / data.total * 100, 10);

		            // Update the hidden input field and trigger a change
		            // so that the jQuery knob plugin knows to update the dial
		            data.context.find('input').val(progress).change();

		            if(progress == 100){
		                data.context.removeClass('working');
		            }
		        },

		        fail:function(e, data){
		            // Something has gone wrong!
		            data.context.addClass('error');
		        }

		    });

		    // Prevent the default action when a file is dropped on the window
		    $(document).on('drop dragover', function (e) {
		        e.preventDefault();
		    });

		    // Helper function that formats the file sizes
		    function formatFileSize(bytes) {
		        if (typeof bytes !== 'number') {
		            return '';
		        }

		        if (bytes >= 1000000000) {
		            return (bytes / 1000000000).toFixed(2) + ' GB';
		        }

		        if (bytes >= 1000000) {
		            return (bytes / 1000000).toFixed(2) + ' MB';
		        }

		        return (bytes / 1000).toFixed(2) + ' KB';
		    }
			
		}


		// in case "Neighbors Graph" clicked
		else if ($(this).text()=="Neighbors Graph" ) {
			$(".modalBody").html("\
				<label>Signal strength:</label>\
				<input id='amount' type='text' class='span1' value='45'>\
				<div id='slider-range-max'></div><hr>\
				<button class='btn'>Refresh</button>\
				<canvas id='viewport' width='500' height='300'></canvas>\
			");

			// slider 
			$(function() {
				$( "#slider-range-max" ).slider({
				  range: "max",
				  min: 20,
				  max: 80,
				  step: 10,
				  value: 40,
				  slide: function( event, ui ) {
					$( "#amount" ).val( ui.value );
				  }
				});
				$( "#amount" ).val( $( "#slider-range-max" ).slider( "value" ) );
			});

			// Graph
			var sys = arbor.ParticleSystem(1000, 400,1);
			sys.parameters({gravity:true});
			sys.renderer = Renderer("#viewport") ;
			var Peyman = sys.addNode('Amy',{'color':'red','shape':'dot','label':'Amy'});
			var Arash = sys.addNode('Stuart',{'color':'blue','shape':'dot','label':'Stuart'});
			var Matteo = sys.addNode('Barry',{'color':'green','shape':'dot','label':'Barry'});
			sys.addEdge(Peyman, Arash);
			sys.addEdge(Arash, Matteo);

			// Insert job into DB
			$("tr.SelectedMote").each(function(){
				var MoteID = $(this).attr("data-MoteID");
				var currentTime = new Date();
				var JsonToSend = {
					"DBTable":"job" ,
					"ActivityID":4 ,
					"GroupID":GroupID ,
					"JobDate":currentTime ,
					"JobID":1 ,
					"MoteID":MoteID ,
				"UserID":3};
				InsertToDB(JsonToSend);
				
			});

		}
		

		else if ($(this).text()=="Serial Forwarder" ) {
			
			$(".modalBody").html("\
				<p>Amy (0):</p>\
		    	<div class='progress progress-striped active'>\
		    		<div class='bar' style='width:40%;'></div>\
		    	</div><hr>\
		    		<p>Stuart (1):</p>\
		    	<div class='progress progress-striped active'>\
		    		<div class='bar' style='width:15%;'></div>\
		    	</div><hr>\
		    		<p>Barry (3):</p>\
		    	<div class='progress progress-striped active'>\
		    		<div class='bar bar-danger' style='width:67%;'></div>\
		    	</div><hr>\
			");

			// Insert job into DB
			$("tr.SelectedMote").each(function(){
				var MoteID = $(this).attr("data-MoteID");
				var currentTime = new Date();
				var JsonToSend = {
					"DBTable":"job" ,
					"ActivityID":4 ,
				  	"GroupID":GroupID ,
				   	"JobDate":currentTime ,
				    "JobID":3 ,
			     	"MoteID":MoteID ,
				"UserID":3};
				InsertToDB(JsonToSend);
				
			});


		}

		else  {
			//$(".modalBody").html("<p>Empty</p>");

			$.post("php/insert.php" );
			$(".modalBody").html("\
				<p>Amy (0):</p>\
		    	<div class='progress progress-striped active'>\
		    		<div class='bar' style='width:40%;'></div>\
		    	</div><hr>\
		    		<p>Stuart (1):</p>\
		    	<div class='progress progress-striped active'>\
		    		<div class='bar' style='width:15%;'></div>\
		    	</div><hr>\
		    		<p>Barry (3):</p>\
		    	<div class='progress progress-striped active'>\
		    		<div class='bar bar-danger' style='width:67%;'></div>\
		    	</div><hr>\
			");
		}

		// show modal anyway
		$("#modalTest").modal("toggle");
		
	};
});

// Set the Coordinates for points which describe the mote position on image
// id: to selecting the target area
// relationalcorrd: to give the relational position of top-left pont of the area as initial point
function setCoord(id,relationalcoord) {
	var h = $("#bigimg1").height();
	var w = $("#bigimg1").width();
	
	var p1h = h /4;
	var p1w = relationalcoord * w;
	var p2h = (3*h) / 4;
	var p2w = p1w + (0.13*w);
	$("#area"+id).attr("coords",p1w+","+p1h+","+p2w+","+p2h);
}

// When area on image clicked, then toggle its existence
$(".area").click("click",function(){
	var i = $(this).attr("data-IDtoToggle");
	$(".mote"+i).toggleClass("hide");
	$(".mote"+i).toggleClass("SelectedMote");
});
	

$("#btnlogin").click(function(){
	$.post("php/select.php" , function(data){
		var a =jQuery.parseJSON(data);
		if ( ($("#user").val()==a.UN) && ($("#pass").val()==a.UP))  {
			//alert("Welcome");
			//$("#btnlogin").attr("href","Home.html");
			$("#error").toggle("slow");
			window.location.href="Home.html";
		}
		else{
			
			// body...
			$("#error").show("slow");
			
		};
	});
});

function InsertToDB(JsonString) {
	$.post("php/insert.php" , JsonString);
}