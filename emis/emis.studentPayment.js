$(function () {

    emis.CreateNamespace('studentPayment');

    (function (context) {
        context.Title = 'Student Payment';
        context.ViewModel = {};

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.ConitnueToPayment = function () {
                    context.ContinueToPayment();
                }

                vm.ContinueToPaymentEsewa = function () {
                    context.ContinueToPaymentEsewa();
                }

                vm.ContinueToPaymentKhalti = function () {
                    context.ContinueToPaymentKhalti();
                }

                vm.ConitnueToPaymentOnePG = function () {
                    context.ContinueToPaymentOnePG();
                }

                vm.ContinueToPaymentConnectIPS = function () {
                    context.ContinueToPaymentConnectIPS();
                }

                vm.PracticalSubjectsCount.subscribe(function (newValue) {
                    newValue = newValue || 0;
                    var pctlAmt = newValue * vm.RatePerSubject();
                    vm.TotalAmount(vm.PaymentAmount() + pctlAmt);
                });

                return vm;
            }
        };

        context.Initialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
        };

        context.ContinueToPayment = function () {
            ajaxRequest('/studentportal/application/HBL', 'POST', { data: { model: "" } }, function (response) {
                if (response.IsSuccess) {
                    $('#paymentGatewayID').val(response.Data.PaymentGatewayId);
                    $('#invoiceNo').val(response.Data.InvoiceNo);
                    $('#productDesc').val(response.Data.ProductDesc);
                    $('#amount').val(response.Data.Amount);
                    $('#currencyCode').val(response.Data.CurrencyCode);
                    $('#userDefined1').val(response.Data.UserDefined1);
                    $('#userDefined2').val(response.Data.UserDefined2);
                    $('#userDefined3').val(response.Data.UserDefined3);
                    $('#userDefined4').val(response.Data.UserDefined4);
                    $('#hashValue').val(response.Data.HashValue);
                    $('#nonSecure').val(response.Data.NonSecure);
                    $('#paymentPostForm')[0].action = response.Data.PostUrl;
                    $('#paymentPostForm')[0].submit();
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })


        }

        context.ContinueToPaymentKhalti = function () {
            let model = ko.toJS(context.ViewModel);
            delete model.__ko_mapping__;
            delete model.ModuleSettings;
            delete model.ConitnueToPayment;
            delete model.ContinueToPaymentEsewa;
            delete model.ContinueToPaymentKhalti;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            ajaxRequest('/studentportal/application/Khalti', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    window.location = response.Data.payment_url;
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.ContinueToPaymentEsewa = function () {
            let model = ko.toJS(context.ViewModel);
            delete model.__ko_mapping__;
            delete model.ModuleSettings;
            delete model.ConitnueToPayment;
            delete model.ContinueToPaymentEsewa;
            delete model.ContinueToPaymentKhalti;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            ajaxRequest('/studentportal/application/Esewa', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    let obj = response.Data;
                    const $form = $("<form>", {
                        action: obj.PostUrl,
                        method: "POST"
                    });

                    const formData = {
                        amount: obj.Amount,
                        tax_amount: 0,
                        total_amount: obj.Amount,
                        transaction_uuid: obj.InvoiceNo,
                        product_code: obj.ProductCode,
                        product_service_charge: 0,
                        product_delivery_charge: 0,
                        success_url: obj.SuccessUrl,
                        failure_url: obj.FailureUrl,
                        signed_field_names: "total_amount,transaction_uuid,product_code",
                        signature: obj.Signature
                    };

                    $.each(formData, (name, value) => {
                        $("<input>", {
                            type: "text",
                            name: name,
                            value: value,
                        }).appendTo($form);
                    });

                    $("<input>", {
                        type: "submit",
                        value: "Submit"
                    }).appendTo($form);

                    $form.appendTo("body");
                    $form.submit();
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.ContinueToPaymentConnectIPS = function () {
            let model = ko.toJS(context.ViewModel);
            delete model.__ko_mapping__;
            delete model.ModuleSettings;
            delete model.ConitnueToPayment;
            delete model.ContinueToPaymentEsewa;
            delete model.ContinueToPaymentKhalti;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            ajaxRequest('/studentportal/application/ConnectIps', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    $('#CIPS_MerchantId').val(response.Data.MerchantId);
                    $('#CIPS_AppId').val(response.Data.AppId);
                    $('#CIPS_AppName').val(response.Data.AppName);
                    $('#CIPS_TxnId').val(response.Data.TxnId);
                    $('#CIPS_TxnDate').val(response.Data.TxnDate);
                    $('#CIPS_TxnCRNCY').val(response.Data.TransactionCurrency);
                    $('#CIPS_TxnAmt').val(response.Data.Amount);
                    $('#CIPS_ReferenceId').val(response.Data.ReferenceId);
                    $('#CIPS_Remarks').val(response.Data.Remarks);
                    $('#CIPS_Particulars').val(response.Data.Particulars);
                    $('#CIPS_Token').val(response.Data.Token);

                    $('#connectIPSPostForm')[0].action = response.Data.GatewayUrl;
                    $('#connectIPSPostForm')[0].submit();
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })


        }

    })(emis.studentPayment);

});