$(function () {

    emis.CreateNamespace('hblPayment');

    (function (context) {
        context.Title = 'Payment';
        context.ViewModel = {};

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            MobileNo: { required: true, rangelength: [10, 13] },
                            Email: { required: true, email: true },
                            ExamFormFeeRateId: { required: true, },
                        }
                    });
                }

                vm.RenderSearchComplete = function () {
                    $('#searchByRegNo').validate({
                        rules: {
                            StudentRegistrationNo: { required: true },
                            DateOfBirthBs: { required: true }
                        }
                    });
                }
                vm.IsStudentVerified = ko.observable(false);

                vm.SearchRegistrationNo = function () {
                    vm.IsStudentVerified(false);
                   
                    if ($("#searchByRegNo").valid()) {
                        ajaxRequest('/Registration/Payment/SearchRegistrationNo', 'POST', { data: { regNo: vm.StudentRegistrationNo(), dob: vm.DateOfBirthBs() } }, function (response) {
                            if (response.IsSuccess) {

                                vm.IsStudentVerified(true);
                            }
                            else {
                                showMessage("Error", response.Message, 'error');
                                vm.IsStudentVerified(false);
                            }
                            ko.mapping.fromJS(response.Data, context.ViewModel.AddNewViewModel);
                        })
                    }
                    else {
                        vm.IsStudentVerified(false);

                    }
                };


                vm.ConitnueToPayment = function () {
                    context.ContiueToPayment();
                }

                vm.ConitnueToPaymentEsewa = function () {
                    context.ContiueToPaymentEsewa();
                }

                vm.ConitnueToPaymentOnePG = function () {
                    context.ContiueToPaymentOnePG();
                }

                vm.ContinueToPaymentConnectIPS = function () {
                    context.ContiuneToPaymentConnectIPS();
                }

                return vm;
            }
        };

        context.Initialize = function (model) {
            context.ViewModel.AddNewViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel.AddNewViewModel, $('#mainContent')[0]);
        };

        context.Search = function () {
            var searchModel = ko.mapping.toJS(context.ViewModel.ListViewModel);
            ajaxRequest('/Admin/Voucher/Index', 'POST', { data: { model: searchModel } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, context.ViewModel.ListViewModel);
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.ContiueToPayment = function () {

            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewViewModel);
            ajaxRequest('/Registration/Payment/HBL', 'POST', { data: { model: model } }, function (response) {
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


        context.ContiueToPaymentEsewa = function () {

            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewViewModel);
            ajaxRequest('/Registration/Payment/ESewa', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    console.log(response.Data);
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

        context.ContiueToPaymentOnePG = function () {

            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewViewModel);
            ajaxRequest('/Registration/Payment/OnePG', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {

                    $('#MerchantId').val(response.Data.MerchantId);
                    $('#MerchantName').val(response.Data.MerchantName);
                    $('#Amount').val(response.Data.Amount);
                    $('#MerchantTxnId').val(response.Data.MerchantTxnId);
                    $('#Signature').val(response.Data.Signature);
                    $('#ProcessId').val(response.Data.ProcessId);
                    $('#TransactionRemarks').val(response.Data.TransactionRemarks);


                    $('#onePGPaymentPostForm')[0].action = response.Data.GatewayUrl;
                    $('#onePGPaymentPostForm')[0].submit();
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })


        }



        context.ContiuneToPaymentConnectIPS = function () {

            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewViewModel);
            ajaxRequest('/Registration/Payment/ConnectIPS', 'POST', { data: { model: model } }, function (response) {
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


        ///

        context.CategoryPaymentMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            FullName: { required: true },
                            DateOfBirthAD: { required: true },
                            MobileNo: { required: true },
                            Email: { required: true },
                        }
                    });
                }

              

                vm.IsAmountCalculated = ko.observable(false);

                vm.CalculateAmount = function () {
                    context.CalculateCategoryBasedAmount();
                }

                vm.ProceedToPayment = function () {
                    context.ProceedToCategoryBasedPayment();
                }

                return vm;
            }
        };


        context.CalculateCategoryBasedAmount = function () {
            context.ViewModel.CategoryAmountViewModel.IsAmountCalculated(false);
            var model = ko.mapping.toJS(context.ViewModel.CategoryAmountViewModel);
            if (model.SelectedCategories) {
                ajaxRequest('/Registration/Payment/CalculateCategoryBasedAmount', 'POST', { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        context.ViewModel.CategoryAmountViewModel.TotalAmount(response.Data.TotalAmount);
                        context.ViewModel.CategoryAmountViewModel.IsAmountCalculated(true);
                    }
                    else {
                        showMessage(context.Title, response.Message, 'error')
                    }
                })
            }
        }

        context.ProceedToCategoryBasedPayment = function () {
            var model = ko.mapping.toJS(context.ViewModel.CategoryAmountViewModel);
            if (model.SelectedCategories) {
                ajaxRequest('/Registration/Payment/CategoryAmountCalculator', 'POST', { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.location = response.Data;
                    }
                    else {
                        showMessage(context.Title, response.Message, 'error')
                    }
                })
            }
        }

        context.InitializeCategoryPayment = function (model) {
            context.ViewModel.CategoryAmountViewModel = ko.mapping.fromJS(model, context.CategoryPaymentMapping);
            ko.applyBindings(context.ViewModel.CategoryAmountViewModel, $('#mainContent')[0]);
        }


    })(emis.hblPayment);

});