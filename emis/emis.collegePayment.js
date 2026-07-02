
$(function () {
    emis.CreateNamespace('collegePayment');

    (function (context) {

        context.Title = 'Payment';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.SavePayment = function () {
                    if (!$("#payment-form").valid()) {
                        return false;
                    }
                    context.SavePayment();
                }

                vm.ConitnueToPayment = function () {
                    if (!$("#payment-form").valid()) {
                        return false;
                    }
                    if ((context.ViewModel.TotalAmount() || 0) == 0) {
                        showMessage("Payment", "Amount must be greater then 0.", 'error')
                        return false;
                    }
                    context.ContinueToPayment();
                }

                vm.ContinueToPaymentEsewa = function () {
                    if (!$("#payment-form").valid()) {
                        return false;
                    }
                    if ((context.ViewModel.TotalAmount() || 0) == 0) {
                        showMessage("Payment", "Amount must be greater then 0.", 'error')
                        return false;
                    }
                    context.ContinueToPaymentEsewa();
                }

                vm.ContinueToPaymentKhalti = function () {
                    if (!$("#payment-form").valid()) {
                        return false;
                    }
                    if ((context.ViewModel.TotalAmount() || 0) == 0) {
                        showMessage("Payment", "Amount must be greater then 0.", 'error')
                        return false;
                    }
                    context.ContinueToPaymentKhalti();
                }

                vm.ConitnueToPaymentOnePG = function () {
                    if (!$("#payment-form").valid()) {
                        return false;
                    }
                    if ((context.ViewModel.TotalAmount() || 0) == 0) {
                        showMessage("Payment", "Amount must be greater then 0.", 'error')
                        return false;
                    }
                    context.ContinueToPaymentOnePG();
                }

                vm.ContinueToPaymentConnectIPS = function () {
                    if (!$("#payment-form").valid()) {
                        return false;
                    }
                    if ((context.ViewModel.TotalAmount() || 0) == 0) {
                        showMessage("Payment", "Amount must be greater then 0.", 'error')
                        return false;
                    }
                    context.ContinueToPaymentConnectIPS();
                }
                return vm;
            }
        };
        context.ContinueToPayment = function () {
            var model = ko.mapping.toJS(context.ViewModel);
            delete model.ConitnueToPayment;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            delete model.ContinueToPaymentKhalti;
            delete model.ContinueToPaymentEsewa;
            delete model.ModuleName;
            delete model.__ko_mapping__;
            ajaxRequest('/exam/collegePayment/HBL', 'POST', { data: { model: model } }, function (response) {
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
            var model = ko.mapping.toJS(context.ViewModel);
            delete model.ConitnueToPayment;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            delete model.ContinueToPaymentKhalti;
            delete model.ContinueToPaymentEsewa;
            delete model.ModuleName;
            delete model.__ko_mapping__;
            ajaxRequest('/exam/collegePayment/Khalti', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    window.location = response.Data.payment_url;
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }
        context.ContinueToPaymentEsewa = function () {
            var model = ko.mapping.toJS(context.ViewModel);
            delete model.ConitnueToPayment;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            delete model.ContinueToPaymentKhalti;
            delete model.ContinueToPaymentEsewa;
            delete model.ModuleName;
            delete model.__ko_mapping__;

            ajaxRequest('/exam/collegepayment/Esewa', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    $('#tAmt').val(response.Data.TotalAmount);
                    $('#txAmt').val(response.Data.TaxAmount);
                    $('#amt').val(response.Data.Amount);
                    $('#psc').val(response.Data.ServiceCharge);
                    $('#pdc').val(response.Data.DeliveryCharge);
                    $('#scd').val(response.Data.MerchantCode);
                    $('#pid').val(response.Data.InvoiceNo);
                    $('#su').val(response.Data.SuccessUrl);
                    $('#fu').val(response.Data.FailUrl);


                    $('#esewaPaymentPostForm')[0].action = response.Data.PostUrl;
                    $('#esewaPaymentPostForm')[0].submit();
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }
        context.ContinueToPaymentConnectIPS = function () {
            var model = ko.mapping.toJS(context.ViewModel);
            delete model.ConitnueToPayment;
            delete model.ConitnueToPaymentOnePG;
            delete model.ContinueToPaymentConnectIPS;
            delete model.ContinueToPaymentKhalti;
            delete model.ContinueToPaymentEsewa;
            delete model.ModuleName;
            delete model.__ko_mapping__;
            ajaxRequest('/exam/collegePayment/ConnectIps', 'POST', { data: { model: model } }, function (response) {
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

        context.PayNow = function (data) {
            ajaxRequest('/exam/collegePayment/GetPaymentList', 'GET', {
                data: { examScheduleId: data.ExamScheduleID }
            }, function (response) {
                if (response.IsSuccess) {
                    window.location.href = "/exam/collegepayment/payment"
                } else {
                    showMessage(context.Title, 'Something went wrong.', 'error');
                }
            });
        }

        context.CollegePaymentInitialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $('#mainContent')[0]);

            $("#StudentCount").on("focus", function () {
                $(this).select();
            });

            $("#StudentCount").on("keyup", function () {
                context.ViewModel.TotalAmount(($(this).val() || 0) * context.ViewModel.Amount())
            });

            $("#payment-form").validate({
                rules: {
                    StudentCount: { required: true, min:1 },
                },
                messages: {
                    StudentCount: { required: 'Student no must be greater then 0.' },
                }

            });
        }

        context.Initialize = function () {
            $(".payment-list").dxDataGrid({
                showRowLines: true,
                showBorders: true,
                allowColumnResizing: true,
                masterDetail: {
                    enabled: true,
                    template: function (c, o) {
                        $("<div />").dxDataGrid({
                            dataSource: o.data.Payments,
                            showRowLines: true,
                            showBorders: true,
                            columns: [
                                {
                                    dataField: "InvoiceNo",
                                    caption: "Voucher No"
                                },
                                {
                                    dataField: "ForwardedTimeStamp",
                                    caption: "Voucher Date"
                                },
                                {
                                    dataField: "Amount",
                                    caption: "Amount"
                                },
                                {
                                    dataField: "StudentCount",
                                    caption: "Students"
                                },

                            ]
                        }).appendTo(c);
                    }
                },
                columns: [
                    {
                        dataField: "ExamScheduleParentName"
                    },
                    {
                        dataField: "ExamScheduleName"
                    },
                    {
                        width: 130,
                        dataField: "Amount",
                        caption: "Paid Amount"
                    },
                    {
                        width: 130,
                        dataField: "StudentCount",
                        caption: "Students Count"
                    },
                    {
                        width: 100,
                        cellTemplate: function (c, o) {
                            $("<a />").text("Pay Now").attr("href", "javascript:void(0)").on("click", function () {
                                context.PayNow(o.data);
                            }).appendTo(c);
                        }
                    }
                ]
            });
            ajaxRequest('/exam/collegePayment/getpayments', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    $(".payment-list").dxDataGrid("instance").option("dataSource", response.Data);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


    })(emis.collegePayment);
});