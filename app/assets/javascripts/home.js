function getTemplate(templateId, dealId) {
  $.ajax({
    url: '/getForm?templateId=' + templateId + '&deal_id=' + dealId,
    success: function(data) {
      console.log(5, data);
      $('#form-container').html(data.template_form);
      $('#stats-container').html(data.template_status);
    },
    error: function (err) {
      console.log('Error in getTemplate');
    }
  })
}

$(function() {
  
});