function getTemplate(templateId) {
  $.ajax({
    url: '/getForm?templateId=' + templateId,
    success: function(data) {
      $('#form-container').html(data);
    },
    error: function (err) {
      console.log('Error in getTemplate');
    }
  })
}

$(function() {
  
});