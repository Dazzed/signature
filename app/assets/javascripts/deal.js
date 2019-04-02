function getTemplate(template_id, deal_id) {
  $.ajax({
    url:
      "/documents/new?template_id=" +
      template_id +
      "&client_deal_id=" +
      deal_id,
    success: function(data) {
      $("#form-container").html(data);
    },
    error: function(err) {
      console.log("Error in getTemplate");
    }
  });
  $(".list-group-item").removeClass("list-group-item-active");
  $(".list-group")
    .find("a[data-template_id='" + template_id + "']")
    .addClass("list-group-item-active");
}

$(function() {
  if (location.pathname.indexOf("/deals") !== -1) {
    $("#deal-details-tab li:nth-child(2) a").tab("show");
  }
});

const nonPreviewTabs = ["#form-tab", "#documents-tab"];

const getPreview = (client, url) => {
  const $container = $("#document-container");
  const $previewContainer = $("#previewContainer");

  $("#preview-tab").click(() => {
    $container.css("display", "none");
    $previewContainer.css("display", "inherit");
    HelloSign.init(client);
    HelloSign.open({
      url,
      skipDomainVerification: true,
      container: document.getElementById("previewContainer"),
      height: 5500
    });
  });

  nonPreviewTabs.forEach(tab => {
    $(tab).click(e => {
      $previewContainer.css("display", "none");
      $container.css("display", "inherit");
    });
  });
};
