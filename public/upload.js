$(document).ready(function(){
	apply_dom_events();
});

function apply_dom_events()
{
	$("#file_upload").change(function() {
		targetFrame = $( '<iframe name="postframe" id="postframe" class="hidden" src="about:none" />' );
    $("#upload_iframe").append(targetFrame);

    $('#uploadform').attr( "enctype", "multipart/form-data" );
    $('#uploadform').attr( "target", "postframe" );
		upload_obj = $('#file_upload').clone();
		$('#file_upload').attr("id", "file_upload_clone");
		$('#uploadform').append($('#file_upload_clone'));
		$("#uploadholder").append(upload_obj);
		
		$("#uploadstatus").show();
		$('#file_upload').hide();
		
        $('#uploadform').submit();
		$('#uploadform').empty();
		
		apply_dom_events();
		
		$("#postframe").load(
            function() {
				$("#uploadstatus").hide();
				$('#file_upload').show();
				page_frame = document.getElementById("postframe");
				if (page_frame == null)
					return;
				json_data = page_frame.contentWindow.document.body.innerText;
				data = jQuery.parseJSON(json_data);
				
				editor_insert = "";
				
				if (data.is_image == true)
				{
					editor_insert = "[![" + data.old_name + "](" + data.image_url +")](" + data.obj_url +")";
				}
				else
				{
					editor_insert = "[" + data.old_name + "](" + data.obj_url +")";
				}
				$("#post_content").val($('#post_content').val() + editor_insert); 
            }
        );
	});
}