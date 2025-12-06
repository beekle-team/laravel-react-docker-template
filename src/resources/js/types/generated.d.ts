declare namespace App.Data {
export type UserData = {
id: number;
name: string;
email: string;
};
}
declare namespace App.Data.Auth {
export type LoginData = {
email: string;
password: string;
remember: boolean;
};
}
