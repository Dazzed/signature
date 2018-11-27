function getTemplate(template_id, dealId) {
  $.ajax({
    url: '/get_form?template_id=' + template_id + '&deal_id=' + dealId,
    success: function(data) {
      console.log(5, data);
      $('#form-container').html(data.template_form);
    },
    error: function (err) {
      console.log('Error in getTemplate');
    }
  })
}

$(function() {
  if (location.pathname.indexOf('init_alternate') !== -1) {
    $('#deal-details-tab li:nth-child(2) a').tab('show');
  }
});