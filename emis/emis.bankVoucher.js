$(function () {
    emis.CreateNamespace('bankVoucher');

    (function (context) {

        context.Title = 'Bank Voucher';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.OriginalAddNewModel = ko.mapping.toJS(vm.AddNewViewModel);

                vm.Search = function () {
                    context.SearchBankVoucherRecords();
                }
                vm.CurrentImageVM = {
                    ImageContent: ko.observable(''),
                    HasContent: ko.observable(false)
                };

                vm.RenderComplete = function () {
                    $('#searchForm').validate({
                        rules: {
                            AcademicYearId: {
                                required: true,
                            },
                            CollegeId: {
                                required: true
                            }
                        }
                    });

                    $('#bankVoucherAddForm').validate({
                        rules: {
                            AcademicYearId: {
                                required: true,
                            },
                            CollegeId: {
                                required: true
                            },
                            BillTitleId: {
                                required: true
                            },
                            BankID: {
                                required: true
                            },
                            VoucherDate: {
                                required: true,
                                date: true
                            },
                            VoucherNo: {
                                required: true
                            },
                            VoucherAmount: {
                                required: true
                            },

                        }
                    });

                }

                //vm.AddNew = function () {
                //    ko.mapping.fromJS(vm.OriginalAddNewModel, {}, vm.AddNewViewModel);
                //    $('#bankVoucherAddModal').modal('show');
                //}

                vm.SaveBankVoucher = function () {
                    context.SaveBankVoucherRecords();
                }

                vm.ShowVoucher = function ($data) {
                    context.ShowVoucher($data)
                }

                return vm;
            }
        };

        context.ShowVoucher = function ($data) {
            var id = $data.BankVoucherId();
            ajaxRequest('/Admin/BankVoucher/ShowBankVoucher', 'GET', {
                data: { id: id }
            }, function (response) {
                if (response.IsSuccess) {
                    context.ViewModel.CurrentImageVM.ImageContent(response.Data.ImageContent)
                    context.ViewModel.CurrentImageVM.HasContent(response.Data.HasContent)

                } else {
                    context.ViewModel.CurrentImageVM.ImageContent('')
                    context.ViewModel.CurrentImageVM.HasContent(false)
                    showMessage(context.Title, response.Message, 'error');

                }
            });
        }



        context.SaveBankVoucherRecords = function () {
            if (!$('#bankVoucherAddForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewViewModel);

            ajaxRequest('/Admin/BankVoucher/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success', function () {
                            window.location = '/Admin/BankVoucher/Index'
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error', function () {
                        });
                    }
                });
        }


        context.Initialize = function () {
            ajaxRequest('/Admin/BankVoucher/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.SearchBankVoucherRecords = function () {
            if (!$('#searchForm').valid()) {
                return false;
            }
            var searchModel = ko.mapping.toJS(context.ViewModel.SearchViewModel);
            delete searchModel.AcademicYears;
            delete searchModel.Colleges;
            delete searchModel.BillTitles;

            ajaxRequest('/Admin/BankVoucher/Index', 'POST', { data: { model: searchModel } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.Records)
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })

        }

        //region : create

        context.CreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.RenderComplete = function () {

                    $('#bankVoucherAddForm').validate({
                        rules: {
                            AcademicYearId: {
                                required: true,
                            },
                            CollegeId: {
                                required: true
                            },
                            BillTitleId: {
                                required: true
                            },
                            BankID: {
                                required: true
                            },
                            VoucherDate: {
                                required: true,
                                date: true
                            },
                            VoucherNo: {
                                required: true
                            },
                            VoucherAmount: {
                                required: true
                            },

                        }
                    });

                    context.InitializeFileUpload();
                }

                vm.SaveBankVoucher = function () {
                    context.SaveBankVoucherRecords();
                }

                return vm;
            }
        };


        context.InitializeCreate = function (model) {

            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel = ko.mapping.fromJS(model, context.CreateMapping);

                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel);
            }
        }

        context.FileUploadAllowedTypes = '["image/png", "image/jpeg"]'


        //
        context.InitializeFileUpload = function (selector = '.upload', maxSize = 1073741824, allowedFileTypes = '["image/png", "image/jpeg"]', oncomplete = null) {
            context.FileUploadAllowedTypes = JSON.parse(allowedFileTypes);
            $(selector).upload({
                maxSize: maxSize,
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Select Document to upload',
                postData: {}
            }).on("start.upload", context.onStart)
                .on("complete.upload", context.onComplete)
                .on("filestart.upload", context.onFileStart)
                .on("fileprogress.upload", context.onFileProgress)
                .on("filecomplete.upload", function (e, file, response) {
                    if (oncomplete != null) {
                        oncomplete(e, file, response);
                    } else {
                        context.onFileComplete(e, file, response)
                    }
                })
                .on("fileerror.upload", context.onFileError)
                .on("chunkstart.upload", context.onChunkStart)
                .on("chunkprogress.upload", context.onChunkProgress)
                .on("chunkcomplete.upload", context.onChunkComplete)
                .on("chunkerror.upload", context.onChunkError)
                .on("queued.upload", context.onQueued);
        };

        context.onCancel = function (e) {
            console.log("Cancel");
            var index = $(this).parents("li").data("index");
            $(this).parents("form").find(".upload").upload("abort", parseInt(index, 10));
        };

        context.onCancelAll = function (e) {
            console.log("Cancel All");
            $(this).parents("form").find(".upload").upload("abort");
        };

        context.onBeforeSend = function (formData, file) {
            console.log("Before Send");
            formData.append("test_field", "test_value");
            var isValid = context.FileUploadAllowedTypes.indexOf(file.file.type) >= 0// === 'image/png' || file.file.type === 'image/jpeg';
            if (!isValid) {
                showMessage(context.Title, 'Invalid File Type.', 'error');
                return false;
            }
            return formData; // cancel all jpgs
        };

        context.onQueued = function (e, files) {
            console.log("Queued");
            var html = '';
            for (var i = 0; i < files.length; i++) {
                html += '<li data-index="' + files[i].index + '"><span class="content"><span class="file">' + files[i].name + '</span><span class="cancel">Cancel</span><span class="progress">Queued</span></span><span class="bar"></span></li>';
            }

            $(this).parents("form").find(".filelist.queue")
                .append(html);
        }

        context.onStart = function (e, files) {
            console.log("Start");
            if (files && files[0]) {
                // context.displayImagePreview(files[0], 'photoId');
            }
            $(this).parents("form").find(".filelist.queue")
                .find("li")
                .find(".progress").text("Waiting");
        }

        context.onComplete = function (e) {
            console.log("Complete");
            // All done!

        }

        context.onFileStart = function (e, file) {
            console.log("File Start");
            $(this).parents("form").find(".filelist.queue")
                .find("li[data-index=" + file.index + "]")
                .find(".progress").text("0%");
        }

        context.onFileProgress = function (e, file, percent) {
            console.log("File Progress");
            var $file = $(this).parents("form").find(".filelist.queue").find("li[data-index=" + file.index + "]");

            $file.find(".progress").text(percent + "%")
            $file.find(".bar").css("width", percent + "%");
        }

        context.onFileComplete = function (e, file, response) {
            var responseObj = eval('(' + response + ')') || {};
            if (responseObj.IsSuccess && responseObj.Data) {

                var uploadContext = $(e.target).attr('data-context');
                switch (uploadContext) {
                    case 'BankVoucherDocument':
                        context.ViewModel.AddNewViewModel.BankVoucherUserAttachmentId(responseObj.Data.Id);
                        $("#previewBankVoucher").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                        break;
                    default:
                    //context.DynamicFileUploadComplete(e, responseObj.Data)

                }
            }
        }

        context.onFileError = function (e, file, error) {
            console.log("File Error");
            $(this).parents("form").find(".filelist.queue")
                .find("li[data-index=" + file.index + "]").addClass("error")
                .find(".progress").text("Error: " + error);
        }

        context.onChunkStart = function (e, file) {
            console.log("Chunk Start");
        }

        context.onChunkProgress = function (e, file, percent) {
            console.log("Chunk Progress");
        }

        context.onChunkComplete = function (e, file, response) {
            console.log("Chunk Complete");
        }

        context.onChunkError = function (e, file, error) {
            console.log("Chunk Error");
        }


    })(emis.bankVoucher);
});