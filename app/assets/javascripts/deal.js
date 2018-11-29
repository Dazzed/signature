function getTemplate(template_id, deal_id) {
  $.ajax({
    url: '/document/new?template_id=' + template_id + '&client_deal_id=' + deal_id,
    success: function (data) {
      $('#form-container').html(data);
    },
    error: function (err) {
      console.log('Error in getTemplate');
    }
  })
}

$(function () {
  if (location.pathname.indexOf('deal/show') !== -1) {
    $('#deal-details-tab li:nth-child(2) a').tab('show');
  }
});