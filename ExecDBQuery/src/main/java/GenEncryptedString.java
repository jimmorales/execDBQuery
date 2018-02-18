/**
 * Created by dsarangi on 2/3/17.
 */
public class GenEncryptedString {
    public static void main(String[] args){
        if(args.length < 1) {
            System.err.print("Please provide the string to be encrypted");
            System.exit(-1);
        }

        Encrypter e = new Encrypter(Constants.ENCRYPTSTR);
        try{
            for (String str: args){
                System.out.println(e.encrypt(str));
            }

        }catch(Exception ex){
            System.err.println("Some error happened encrypting the string");
            System.err.println(ex.getMessage());
        }
    }
}
