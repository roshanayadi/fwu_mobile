$(function () {
    emis.CreateNamespace('studentDasboard');

    (function (context) {
        context.count = 0;
        context.Title = 'Student Dashboard';
        context.ViewModel = {};
        context.ViewModel.Data = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.isEditingContact = ko.observable(false);
                vm.isEditingEmail = ko.observable(false);
                vm.InitializeEntry = function ($data) {
                    context.InitializeEntry($data)
                }
                vm.PayPractical = function ($data) {
                    context.PayPractical($data)
                }

                vm.CustomVoucher = function ($data) {
                    context.CustomVoucher($data);
                }

                vm.InitializeConfirmationPageDownload = function ($data) {
                    context.InitializeConfirmationPageDownload($data)
                }

                vm.InitializeAdmitCardDownload = function ($data) {
                    context.InitializeAdmitCardDownload($data)
                }

                vm.toggleEditContact = () => {
                    if (!vm.isEditingContact()) {
                        setTimeout(() => {
                            document.querySelector('#contactInput').focus();
                        }, 0);
                    }

                    if (vm.isEditingContact() && vm.ContactNo()) {
                        ajaxRequest('/StudentPortal/dashboard/UpdateContactNo', 'GET', { data: { ContactNo: vm.ContactNo()} }, function (response) {
                            if (response.IsSuccess) {
                                showMessage(context.Title, response.Message, 'success')
                            }
                            else {
                                showMessage(context.Title, response.Message, 'error')
                            }
                        })
                    }
                    vm.isEditingContact(!vm.isEditingContact());
                };

                vm.toggleEditEmail = () => {

                    if (!vm.isEditingEmail()) {
                        setTimeout(() => {
                            document.querySelector('#emailInput').focus();
                        }, 0);
                    }

                    const isValidEmail = (email) => {
                        if (!email) return false;
                        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
                        return emailRegex.test(email);
                    };


                    if (vm.isEditingEmail() && vm.Email()) {
                        if (!isValidEmail(vm.Email())) {
                            showMessage('Invalid Email', 'Please enter a valid email address.', 'error');
                            return; 
                        }
                        ajaxRequest('/StudentPortal/dashboard/UpdateEmail', 'GET', { data: { Email: vm.Email() } }, function (response) {
                            if (response.IsSuccess) {
                                showMessage(context.Title, response.Message, 'success')
                            }
                            else {
                                showMessage(context.Title, response.Message, 'error')
                            }
                        })
                    }
                    vm.isEditingEmail(!vm.isEditingEmail());
                };
                return vm;
            },
        };

        context.PayPractical = function ($data) {
            ajaxRequest('/StudentPortal/Application/Initialize', 'POST', { data: { studentAdmissionId: $data.StudentAdmissionId(), examScheduleId: $data.ExamScheduleId() } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/StudentPortal/Application/PayPractical'
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.CustomVoucher = function (data) {
            swal({
                title: "Khalti Voucher Validation",
                text: "Please input your six digits voucher code.",
                type: "input",
                showCancelButton: true,
                closeOnConfirm: false,
                showLoaderOnConfirm: true,
                inputPlaceholder: "Voucher No"
            }, function (inputValue) {
                if (inputValue === false) return false;
                if (inputValue === "") {
                    swal.showInputError("Voucher no is required");
                    return false
                }
                ajaxRequest("/studentportal/application/customvoucher", 'POST', { data: { ExamScheduleId: data.ExamScheduleId(), customVoucher: inputValue } }, function (res) {
                    if (res.IsSuccess) {
                        swal("Success", res.Message, "success")
                        setTimeout(() => {
                            window.location.reload();
                        }, 3000)
                    }
                    else {
                        swal("Error", res.Message, "error")
                    }

                })

            });
        }

        context.DynamicFileUploadAllowedTypes = ['image/png', 'image/jpeg', 'image/jpg'];
        context.maxSize = 2 * 1024 * 1024;

        context.InitializeFileUpload = function (oldid, oncomplete) {
            $(".upload").upload({
                maxSize: context.maxSize,
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Select Photo to update',
                postData: {}
            }).on("filecomplete.upload", oncomplete)
        };

        context.InitializeEntry = function ($data) {
            ajaxRequest('/StudentPortal/Application/Initialize', 'POST', { data: { studentAdmissionId: $data.StudentAdmissionId(), examScheduleId: $data.ExamScheduleId() } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/StudentPortal/Application/Index'
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.InitializeConfirmationPageDownload = function ($data) {
            ajaxRequest('/StudentPortal/Application/InitializeConfirmationpage', 'POST', { data: { studentAdmissionId: $data.StudentAdmissionId(), examRegistrationId: $data.ExamRegistrationId(), examScheduleId: $data.ExamScheduleId() } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/StudentPortal/Application/Download'
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }
        context.InitializeAdmitCardDownload = function ($data) {
            window.location = '/registration/default/downloadadmitcardbystudent?examscheduleId=' + $data.ExamScheduleId();
            //ajaxRequest('/StudentPortal/Application/InitializeAdmitCard', 'POST', { data: { studentAdmissionId: $data.StudentAdmissionId(), examRegistrationId: $data.ExamRegistrationId(), examScheduleId: $data.ExamScheduleId() } }, function (response) {
            //    if (response.IsSuccess) {
            //    }
            //    else {
            //        showMessage(context.Title, response.Message, 'error')
            //    }
            //})
        }

        context.InitializeSignUpload = function (oldid, oncomplete) {
            $(".signUpload").upload({
                maxSize: context.maxSize,
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Select Sign to update',
                postData: {}
            }).on("filecomplete.upload", oncomplete)
        };

        context.onBeforeSend = function (formData, file) {
            var isValid = context.DynamicFileUploadAllowedTypes.indexOf(file.file.type) >= 0// === 'image/png' || file.file.type === 'image/jpeg';
            if (!isValid) {
                showMessage(context.Title, 'Invalid File Type. Only Png or JPEG is supported.', 'error');
                return false;
            }
            return formData; // cancel all jpgs
        };

        context.Initialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel);
             //for photo attachment
            if (model.SignatureAttachmentId) {
                ajaxRequest('/studentportal/dashboard/GetFile/' + model.SignatureAttachmentId, 'GET', null, function (response) {
                    if (response.IsSuccess) {
                        $(".sign-stu").attr("src", "data:image/;base64," + response.Data);
                    }
                });
            }

            if (model.PhotoAttachmentId) {
                ajaxRequest('/studentportal/dashboard/GetFile/' + model.PhotoAttachmentId, 'GET', null, function (response) {
                    if (response.IsSuccess) {
                        $(".img-stu").attr("src", "data:image/;base64," + response.Data);
                    }
                });
            }

            context.InitializeFileUpload(null, function (e, file, response) {
                var responseObj = JSON.parse(response || "{}");
                if (responseObj.IsSuccess && responseObj.Data) {
                    ajaxRequest('/studentportal/dashboard/UpdatePhoto/', 'POST', { data: { id: responseObj.Data.Guid } }, function (response) {
                        if (response.IsSuccess) {
                            $(".img-stu").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                            showMessage(context.Title, "Photo updated sucessfully.", 'success')
                        }
                        else {
                            showMessage(context.Title, response.Message, 'error')
                        }
                    });
                }
            });
            context.InitializeSignUpload(null, function (e, file, response) {
                var responseObj = JSON.parse(response || "{}");
                if (responseObj.IsSuccess && responseObj.Data) {
                    ajaxRequest('/studentportal/dashboard/UpdateSign/', 'POST', { data: { id: responseObj.Data.Guid } }, function (response) {
                        if (response.IsSuccess) {
                            $(".sign-stu").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                            showMessage(context.Title, "Sign updated sucessfully.", 'success')
                        }
                        else {
                            showMessage(context.Title, response.Message, 'error')
                        }
                    });
                }
            });
        };
    })(emis.studentDasboard);
});