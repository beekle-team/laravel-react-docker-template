import { Head, useForm } from "@inertiajs/react";
import type { FormEventHandler } from "react";
import { store as confirmPasswordStore } from "@/actions/App/Http/Controllers/Auth/ConfirmablePasswordController";
import InputError from "@/Components/InputError";
import InputLabel from "@/Components/InputLabel";
import PrimaryButton from "@/Components/PrimaryButton";
import TextInput from "@/Components/TextInput";
import GuestLayout from "@/Layouts/GuestLayout";

export default function ConfirmPassword() {
    const {
        data,
        setData,
        submit: submitForm,
        processing,
        errors,
        reset,
        validate,
    } = useForm(confirmPasswordStore(), {
        password: "",
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        submitForm(confirmPasswordStore(), {
            onFinish: () => reset("password"),
        });
    };

    return (
        <GuestLayout>
            <Head title="Confirm Password" />

            <div className="mb-4 text-sm text-gray-600">
                This is a secure area of the application. Please confirm your password before
                continuing.
            </div>

            <form onSubmit={submit}>
                <div className="mt-4">
                    <InputLabel htmlFor="password" value="Password" />

                    <TextInput
                        id="password"
                        type="password"
                        name="password"
                        value={data.password}
                        className="mt-1 block w-full"
                        isFocused={true}
                        onChange={(e) => setData("password", e.target.value)}
                        onBlur={() => validate("password")}
                    />

                    <InputError message={errors.password} className="mt-2" />
                </div>

                <div className="mt-4 flex items-center justify-end">
                    <PrimaryButton className="ms-4" disabled={processing}>
                        Confirm
                    </PrimaryButton>
                </div>
            </form>
        </GuestLayout>
    );
}
