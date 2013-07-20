
var GroupID=0;
$(".MotesGroup").click(function(){
	GroupID = $(this).attr("data-groupID");
	//alert("GroupID : "+GroupID);
});

$("#bigImgCon").css("background-color","black");
$("body").css("background-color","#E9EDF5");

// when Group image clicked
$("#img1").click(function(){
	$("#bigImgCon").slideToggle("slow");
	$(".btnselector").toggleClass("disabled");

	// setting the position of motes on image
		setCoord("bigimg1" , 1 , 0.11 , 0.23 , 0.27 , 0.75);
		setCoord("bigimg1" , 2 , 0.44 , 0.23 , 0.59 , 0.77);
		setCoord("bigimg1" , 3 , 0.73 , 0.26 , 0.87 , 0.78);
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

// Event: after corousel image changed do:
$("#myCarousel").on("slid",function(e){
	var index = $("#myCarousel .active").index();

	if (index == 0){
		setCoord("bigimg1" , 1 , 0.11 , 0.23 , 0.27 , 0.75);
		setCoord("bigimg1" , 2 , 0.44 , 0.23 , 0.59 , 0.77);
		setCoord("bigimg1" , 3 , 0.73 , 0.26 , 0.87 , 0.78);
	}
	else if (index == 1) {
		setCoord("bigimg2" , 1 , 0.2 , 0.11 , 0.43 , 0.85);
		setCoord("bigimg2" , 2 , 0.53 , 0.27 , 0.65 , 0.76);
		setCoord("bigimg2" , 3 , 0.7 , 0.37 , 0.78 , 0.73);
	} 
	else if (index == 2){
		setCoord("bigimg3" , 1 , 0.15 , 0.30 , 0.23 , 0.64);
		setCoord("bigimg3" , 2, 0.32 , 0.27 , 0.45 , 0.73);
		setCoord("bigimg3" , 3 , 0.61 , 0.14 , 0.82 , 0.83);
	}
});

// setting area coordinates for selecting/deselecting motes
// patter:    (Id of the image , MoteID , x_coord of top-left , y_coor of top-left , x_coord of bottom-right , y_coord of bottom-right) 
// ****************  coord values are ratio  **************************
function setCoord(imgID , id , rx1 , ry1 , rx2 , ry2) {
	var h = $("#"+imgID).height();
	var w = $("#"+imgID).width();

	var p1h = ry1 * h;
	var p1w = rx1 * w;
	var p2h = ry2 * h;
	var p2w = rx2 * w;

	$("#area"+id).attr("coords",p1w+","+p1h+","+p2w+","+p2h);
}


$("#btnDeselectAll").on("click",function(){
	$(".SelectedMote").toggleClass("hide SelectedMote");
});

$("#btnSelectAll").on("click",function(){
	$("tr.hide").toggleClass("hide SelectedMote");
});