import InputError from "@/Components/InputError";
import PrimaryButton from "@/Components/PrimaryButton";
import TextInput from "@/Components/TextInput";
import GuestLayout from "@/Layouts/GuestLayout";
import { store as passwordEmailStore } from "@/actions/App/Http/Controllers/Auth/PasswordResetLinkController";
import { Head, useForm } from "@inertiajs/react";
import type { FormEventHandler } from "react";

export default function ForgotPassword({ status }: { status?: string }) {
    const {
        data,
        setData,
        submit: submitForm,
        processing,
        errors,
        validate,
    } = useForm(passwordEmailStore(), {
        email: "",
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        submitForm(passwordEmailStore());
    };

    return (
        <GuestLayout>
            <Head title="Forgot Password" />

            <div className="mb-4 text-sm text-gray-600">
                Forgot your password? No problem. Just let us know your email address and we will
                email you a password reset link that will allow you to choose a new one.
            </div>

            {status && <div className="mb-4 text-sm font-medium text-green-600">{status}</div>}

            <form onSubmit={submit}>
                <TextInput
                    id="email"
                    type="email"
                    name="email"
                    value={data.email}
                    className="mt-1 block w-full"
                    isFocused={true}
                    onChange={(e) => setData("email", e.target.value)}
                    onBlur={() => validate("email")}
                />

                <InputError message={errors.email} className="mt-2" />

                <div className="mt-4 flex items-center justify-end">
                    <PrimaryButton className="ms-4" disabled={processing}>
                        Email Password Reset Link
                    </PrimaryButton>
                </div>
            </form>
        </GuestLayout>
    );
}
